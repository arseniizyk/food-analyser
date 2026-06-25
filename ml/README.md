# Food OCR Service

FastAPI server for optical character recognition (OCR) with Russian language support using PaddleOCR.

## Installation

1. Create a Python 3.9+ virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

## Running the Server

Start the OCR service:

```bash
python main.py
```

Server will be available at `http://localhost:8000`

**Tip:** First run will download the PaddleOCR model (~150MB). Subsequent runs will be faster.

## API Endpoints

### `/health` (GET)

Health check endpoint.

**Response:**

```json
{ "status": "ok" }
```

### `/ocr` (POST)

Recognize text from an image.

**Request:** Multipart form with image file

```bash
curl -X POST -F "file=@image.jpg" http://localhost:8000/ocr
```

**Response:**

```json
{
    "text": "Extracted text from the image",
    "confidence": 0.95,
    "lines": [
        { "text": "Line 1 text", "confidence": 0.97 },
        { "text": "Line 2 text", "confidence": 0.93 }
    ]
}
```

## Configuration

- **Host:** 0.0.0.0 (accessible from all network interfaces)
- **Port:** 8000
- **OCR Language:** Russian (`ru`)
- **Angle Detection:** Enabled (handles rotated text)

## Connecting from Flutter App

Update the Flutter app to point to this OCR service:

In `lib/app/app_providers.dart`, change the OCR service URL:

```dart
const String ocrServiceUrl = 'http://your-server:8000';  // For local dev: http://192.168.x.x:8000
```

## Performance Notes

- First request after startup will take longer (~5-10s) as model is loaded
- Typical OCR request: 1-3 seconds per image
- Russian text recognition accuracy: ~85-95% depending on image quality
- For better results:
    - Use well-lit images
    - Ensure text is sharp and not skewed
    - Avoid partial/cut-off text regions

## Deployment

For production deployment, consider:

- Using Docker (recommended)
- Running behind an nginx reverse proxy
- Using Gunicorn with multiple workers: `gunicorn -k uvicorn.workers.UvicornWorker main:app --workers 2 --bind 0.0.0.0:8000`
