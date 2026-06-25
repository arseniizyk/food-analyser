"""
FastAPI server for OCR recognition using PaddleOCR.
Supports Russian text recognition for food ingredient labels.
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
                    "Initializing PaddleOCR model (first run may download ~150MB)...")
                _ocr = PaddleOCR(use_angle_cls=True, lang="ru")
                logger.info("PaddleOCR model loaded successfully")
    return _ocr


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
    version="1.1.0",
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
        f"Received OCR request: filename={file.filename}, content_type={file.content_type}")

    try:
        content = await file.read()

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

        logger.info("Running OCR inference...")
        ocr_service = get_ocr()
        image_array = np.array(image.convert("RGB"))
        result = ocr_service.ocr(image_array)

        if not result or not result[0]:
            logger.info("No text detected in image")
            return {"text": "", "confidence": 0.0, "lines": []}

        extracted_lines = []
        all_texts = []
        all_confidences = []

        for line in result[0]:
            if len(line) >= 3:
                bbox, text, confidence = line[0], line[1], line[2]
            elif len(line) == 2:
                bbox = line[0]
                text, confidence = line[1]
            else:
                continue
            extracted_lines.append(
                {"text": text, "confidence": float(confidence)}
            )
            all_texts.append(text)
            all_confidences.append(float(confidence))

        full_text = " ".join(all_texts)
        avg_confidence = (
            sum(all_confidences) / len(all_confidences)
            if all_confidences
            else 0.0
        )

        logger.info(
            f"OCR completed: lines={len(extracted_lines)}, avg_conf={avg_confidence:.3f}"
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

    import sys
    sys.argv = ["uvicorn", "main:app", "--host", HOST,
                "--port", str(PORT), "--log-level", "info"]
    uvicorn.main()
