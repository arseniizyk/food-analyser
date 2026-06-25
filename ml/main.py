"""
FastAPI server for OCR recognition using PaddleOCR.
Supports Russian text recognition for food ingredient labels.
Compatible with PaddleOCR 2.x and 3.x.
"""

import io
import logging
import os
import threading
from contextlib import asynccontextmanager

import numpy as np
import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from paddleocr import PaddleOCR
from PIL import Image

# ---------------------------
# CONFIG
# ---------------------------
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

# ---------------------------
# LOGGING SETUP
# ---------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

logger = logging.getLogger("ocr-service")

# ---------------------------
# OCR SINGLETON (thread-safe)
# ---------------------------
_ocr: PaddleOCR | None = None
_ocr_lock = threading.Lock()


def get_ocr() -> PaddleOCR:
    global _ocr
    if _ocr is None:
        with _ocr_lock:
            if _ocr is None:
                logger.info(
                    "Initializing PaddleOCR model (first run may download ~150MB)..."
                )
                _ocr = PaddleOCR(use_angle_cls=True, lang="ru")
                logger.info("PaddleOCR model loaded successfully")
    return _ocr


def parse_ocr_result(result) -> tuple[list[str], list[float]]:
    """
    Parse PaddleOCR result into (texts, confidences).

    PaddleOCR 3.x: result is a list of dicts with keys rec_texts / rec_scores.
    PaddleOCR 2.x: result is a list of lists [[bbox, (text, conf)], ...].
    """
    if not result or not result[0]:
        return [], []

    page = result[0]

    # --- PaddleOCR 3.x ---
    if isinstance(page, dict):
        rec_texts = page.get("rec_texts", [])
        rec_scores = page.get("rec_scores", [])
        logger.info(f"PaddleOCR 3.x format detected: {len(rec_texts)} lines")
        texts, confs = [], []
        for text, conf in zip(rec_texts, rec_scores):
            if isinstance(text, str) and text.strip():
                texts.append(text)
                confs.append(float(conf))
        return texts, confs

    # --- PaddleOCR 2.x ---
    logger.info("PaddleOCR 2.x format detected")
    texts, confs = [], []
    for line in page:
        if not isinstance(line, (list, tuple)) or len(line) < 2:
            logger.warning(f"Skipping unexpected line: {line}")
            continue

        text_conf = line[1]

        if not isinstance(text_conf, (list, tuple)) or len(text_conf) != 2:
            logger.warning(f"Skipping unexpected text_conf: {text_conf}")
            continue

        text, conf = text_conf
        if isinstance(text, str) and text.strip():
            texts.append(text)
            confs.append(float(conf))

    return texts, confs


# ---------------------------
# FASTAPI APP (lifespan)
# ---------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting OCR service...")
    get_ocr()
    logger.info("OCR service is ready and running")
    yield


app = FastAPI(
    title="Food OCR Service",
    description="REST API for ingredient text recognition",
    version="1.3.0",
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
    return {"status": "ok", "ocr": "ready"}


@app.post("/ocr")
async def recognize_text(file: UploadFile = File(...)):
    """
    Recognize text from an image.
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
        except Exception:
            logger.warning("Uploaded file could not be decoded as an image")
            raise HTTPException(
                status_code=400,
                detail="Uploaded file is not a valid image",
            )

        logger.info(f"Image loaded: size={image.size}, mode={image.mode}")
        logger.info("Running OCR inference...")

        ocr_service = get_ocr()
        image_array = np.array(image.convert("RGB"))
        result = ocr_service.ocr(image_array)

        all_texts, all_confidences = parse_ocr_result(result)

        if not all_texts:
            logger.info("No text detected in image")
            return {"text": "", "confidence": 0.0, "lines": []}

        extracted_lines = [
            {"text": text, "confidence": round(conf, 3)}
            for text, conf in zip(all_texts, all_confidences)
        ]

        full_text = " ".join(all_texts)
        avg_confidence = sum(all_confidences) / len(all_confidences)

        logger.info(
            f"OCR result: {full_text}"
            f"OCR completed: lines={len(extracted_lines)}, "
            f"avg_conf={avg_confidence:.3f}"
        )

        return {
            "text": full_text,
            "confidence": round(avg_confidence, 3),
            "lines": extracted_lines,
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
    logger.info(f"Launching uvicorn server on {HOST}:{PORT}")
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
