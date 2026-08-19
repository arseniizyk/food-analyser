"""
FastAPI server for OCR recognition using PaddleOCR-VL.
Supports Russian text recognition for food ingredient labels.

Migrated from classic PaddleOCR (PP-OCR detection+recognition pipeline)
to PaddleOCR-VL (layout detection + vision-language model recognition).

IMPORTANT DIFFERENCES FROM THE CLASSIC PIPELINE:
1. No `lang` parameter — PaddleOCR-VL is a single unified multilingual
   model (109 languages including Russian), it auto-detects the script.
2. No calibrated per-line confidence score. The old pipeline had a
   dedicated recognition head that output a probability per line;
   PaddleOCR-VL is a generative VLM and does not expose an equivalent
   trustworthy score. The `confidence` field below is therefore a
   coarse heuristic (1.0 if parsing succeeded and text was found,
   0.0 otherwise) — do NOT treat it as a real per-line quality signal
   the way the old avg_conf was used. If you need confidence-based
   routing/fallback again, we can reintroduce the classic PP-OCR as a
   first-pass gate later.
3. Local PaddleOCR-VL-0.9B currently only supports batch size 1 per
   call, which is fine for this per-request API design.
4. Output is block-based (text/title/table/formula/...), not strictly
   line-based, so `lines` here means "recognized blocks in reading
   order", which is usually more useful for ingredient labels anyway.
"""

import io
import logging
import os
import re
import threading
from contextlib import asynccontextmanager

import numpy as np
import uvicorn
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from paddleocr import PaddleOCRVL
from PIL import Image, UnidentifiedImageError

# ---------------------------
# CONFIG
# ---------------------------
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
PORT = int(os.getenv("ML_PORT", "8888"))
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

# gpu:0 by default; set OCR_DEVICE=cpu if no/not-enough VRAM
OCR_DEVICE = os.getenv("OCR_DEVICE", "gpu:0")
# Ingredient lists can be long — raise this if output gets truncated
MAX_NEW_TOKENS = int(os.getenv("OCR_MAX_NEW_TOKENS", "4096"))
# Photos of packaging are often skewed/curved/rotated — correct that
# before the VLM reads the block. Turn off if it ever hurts your data.
USE_DOC_ORIENTATION_CLASSIFY = (
        os.getenv("OCR_USE_DOC_ORIENTATION_CLASSIFY", "true").lower() == "true"
)
USE_DOC_UNWARPING = os.getenv("OCR_USE_DOC_UNWARPING", "true").lower() == "true"

# ---------------------------
# LOGGING SETUP
# ---------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

logger = logging.getLogger("ocr-service")

# PaddleOCR-VL is a generative VLM: for crop regions with no readable text
# (blurry/empty/marginal areas) it emits a boilerplate refusal sentence
# instead of hallucinating. Filter those blocks out of the output.
_NO_TEXT_PATTERNS = [
    re.compile(r"image is too blurry", re.IGNORECASE),
    re.compile(r"no text (?:found|detected) in the image", re.IGNORECASE),
    re.compile(r"there is no text in the image", re.IGNORECASE),
    re.compile(r"cannot recognize", re.IGNORECASE),
]


def _is_model_refusal(text: str) -> bool:
    return any(p.search(text) for p in _NO_TEXT_PATTERNS)

# ---------------------------
# OCR SINGLETON (thread-safe)
# ---------------------------
_ocr: PaddleOCRVL | None = None
_ocr_lock = threading.Lock()


def get_ocr() -> PaddleOCRVL:
    global _ocr
    if _ocr is None:
        with _ocr_lock:
            if _ocr is None:
                logger.info(
                    f"Initializing PaddleOCR-VL pipeline (device={OCR_DEVICE}, "
                    "first run may download ~1-2GB of weights)..."
                )
                try:
                    _ocr = PaddleOCRVL(
                        device=OCR_DEVICE,
                        use_doc_orientation_classify=USE_DOC_ORIENTATION_CLASSIFY,
                        use_doc_unwarping=USE_DOC_UNWARPING,
                    )
                except Exception:
                    logger.exception(
                        f"Failed to init PaddleOCR-VL on device={OCR_DEVICE}, "
                        "falling back to CPU"
                    )
                    _ocr = PaddleOCRVL(
                        device="cpu",
                        use_doc_orientation_classify=USE_DOC_ORIENTATION_CLASSIFY,
                        use_doc_unwarping=USE_DOC_UNWARPING,
                    )
                logger.info("PaddleOCR-VL pipeline loaded successfully")
    return _ocr


def parse_ocr_result(result) -> tuple[list[dict], str]:
    """
    Parse a PaddleOCR-VL result into (blocks, full_text).

    Each PaddleOCRVLResult (one per input image) exposes a `.json` dict
    with a `parsing_res_list`, a list of blocks in reading order, each
    with `label` (text/title/table/formula/...) and `content`.
    """
    if not result:
        return [], ""

    page = result[0]
    data = page.json if hasattr(page, "json") else page

    # `.json` mirrors save_to_json() output; the payload sometimes sits
    # one level down under "res" depending on paddleocr version.
    payload = data.get("res", data) if isinstance(data, dict) else {}
    parsing_res_list = payload.get("parsing_res_list", []) or []

    blocks = []
    text_parts = []
    for item in parsing_res_list:
        label = item.get("block_label", item.get("label", "text"))
        content = item.get("block_content", item.get("content", ""))
        content = content.strip() if isinstance(content, str) else ""
        if not content or _is_model_refusal(content):
            continue
        blocks.append({"label": label, "text": content})
        text_parts.append(content)

    full_text = "\n".join(text_parts)
    return blocks, full_text


# ---------------------------
# FASTAPI APP (lifespan)
# ---------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting OCR service (PaddleOCR-VL)...")
    get_ocr()
    logger.info("OCR service is ready and running")
    yield


app = FastAPI(
    title="Food OCR Service",
    description="REST API for ingredient text recognition (PaddleOCR-VL)",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    """Health check endpoint."""
    ocr_ready = _ocr is not None
    if not ocr_ready:
        return {"status": "degraded", "ocr": "not_loaded"}
    return {"status": "ok", "ocr": "ready", "device": OCR_DEVICE}


@app.post("/ocr")
async def recognize_text(file: UploadFile = File(...)):  # noqa: B008
    """
    Recognize text from an image using PaddleOCR-VL.
    """
    logger.info(
        f"Received OCR request: filename={file.filename}, "
        f"content_type={file.content_type}"
    )

    try:
        content = await file.read()
        logger.info(f"File size: {len(content)} bytes")

        if len(content) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail=f"File too large. Maximum size is {MAX_FILE_SIZE // (1024 * 1024)}MB",
            )

        try:
            image = Image.open(io.BytesIO(content))
            image.load()
        except UnidentifiedImageError:
            logger.warning("Uploaded file could not be decoded as an image")
            raise HTTPException(
                status_code=400,
                detail="Uploaded file is not a valid image",
            )

        logger.info(f"Image loaded: size={image.size}, mode={image.mode}")
        logger.info("Running PaddleOCR-VL inference...")

        ocr_service = get_ocr()
        image_array = np.array(image.convert("RGB"))

        result = list(
            ocr_service.predict(
                image_array,
                use_doc_orientation_classify=USE_DOC_ORIENTATION_CLASSIFY,
                use_doc_unwarping=USE_DOC_UNWARPING,
                max_new_tokens=MAX_NEW_TOKENS,
            )
        )

        blocks, full_text = parse_ocr_result(result)

        if not full_text:
            logger.info("No text detected in image")
            return {"text": "", "confidence": 0.0, "lines": []}

        # See module docstring: this is a coarse heuristic, not a
        # calibrated per-line score like the old avg_conf was.
        confidence = 1.0

        logger.info(
            f"OCR result: {full_text} | "
            f"OCR completed: blocks={len(blocks)}, confidence(heuristic)={confidence:.3f}"
        )

        return {
            "text": full_text,
            "confidence": confidence,
            "lines": blocks,
        }

    except HTTPException:
        raise
    except Exception:
        logger.exception("OCR processing failed")
        raise HTTPException(
            status_code=500,
            detail="Internal OCR processing error",
        )


if __name__ == "__main__":
    logger.info(f"Launching uvicorn server on 0.0.0.0:{PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="info")