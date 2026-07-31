# Food Analyser Project

This is a microservice-based food analysis platform consisting of:
- Flutter mobile application (`/app`)
- Go backend service (`/backend`) 
- Python ML OCR service (`/ml`)
- PostgreSQL database
- Docker Compose orchestration

## Project Structure

```
food-analyser/
├── app/                  # Flutter mobile application
├── backend/              # Go REST API backend
│   ├── api/              # OpenAPI specs
│   ├── cmd/              # Application entrypoints
│   ├── configs/          # Configuration examples
│   ├── internal/         # Business logic
│   │   ├── handler/      # HTTP handlers
│   │   ├── repository/   # Data access layer
│   │   ├── service/      # Business logic services
│   │   └── models/       # Data models
│   └── migrations/       # Database migrations
├── ml/                   # Python ML OCR service
├── static/               # Static assets
├── docker-compose.yml    # Docker orchestration
└── Taskfile.yml          # Task runner configuration
```

## Development Workflow

### Prerequisites
- Docker Desktop or Docker Engine with Compose plugin
- Go 1.26+ (for backend development)
- Python 3.11+ (for ML service development)
- Flutter SDK 3.12+ (for mobile development)
- Task runner (optional, for task automation)

### Local Development Setup

#### 1. Backend Service (Go)
```bash
cd backend
task deps:update          # Install dependencies
go run ./cmd/migrate -path ./configs/example.env  # Run migrations
go run ./cmd/app -path ./configs/example.env       # Start server
```

#### 2. ML Service (Python)
```bash
cd ml
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload  # Development mode
```

#### 3. Mobile App (Flutter)
```bash
cd app
flutter pub get           # Install dependencies
flutter run               # Run on emulator/device
```

### Docker Development

```bash
# Start all services
task up

# View logs
task logs

# Stop services
task down
```

Services will be available at:
- Backend API: http://localhost:8000
- ML OCR Service: http://localhost:8001
- PostgreSQL: localhost:5432

## Taskfile Commands

Root-level tasks:
- `task up` - Start all services with Docker Compose
- `task down` - Stop all services
- `task logs` - Follow container logs
- `task ps` - List running containers
- `task lint` - Run Go and Python linters
- `task format` - Format Go code
- `task app:deps` - Install Flutter dependencies
- `task app:run` - Run Flutter app
- `task app:build` - Build Flutter APK

Backend-specific tasks (run `task --list` in backend/ for more):
- `backend:lint` - Run Go linters
- `backend:format` - Format Go code
- `backend:gen` - Generate OpenAPI client code
- `backend:deps:update` - Update Go dependencies

ML-specific tasks (run `task --list` in ml/ for more):
- `ml:format` - Format Python code
- `ml:lint` - Lint Python code
- `ml:typecheck` - Type check Python code

## API Endpoints

### Backend Service
- `GET /api/v1/product/{barcode}` - Get product by barcode
- `POST /api/v1/analyze/{barcode}` - Analyze product ingredients
- `POST /api/v1/auth/google` - Google OAuth authentication

### ML Service
- `GET /health` - Health check
- `POST /ocr` - Extract text from image (multipart/form-data)

## Code Style Guidelines

### Go Backend
- Uses `gofumpt` for formatting
- Uses `gci` for import ordering
- Linted with `golangci-lint`
- Follows standard Go project layout
- Uses `chi` router with `slog` logging
- OpenAPI 3.0 spec-driven development

### Python ML Service
- Follows PEP 8 style guidelines
- Uses `black` for formatting (implicit in task definitions)
- Type hints encouraged
- Thread-safe singleton pattern for ML model loading

### Flutter App
- Uses Riverpod for state management
- Follows Flutter/Dart best practices
- Widget-first UI approach
- Proper error handling and loading states

## Database

PostgreSQL database schema is managed through migrations in `/backend/migrations/`.
Run migrations with: `go run ./cmd/migrate -path ./configs/example.env`

## Testing

Each service has its own testing approach:
- Backend: Go testing framework (`go test`)
- ML Service: Pytest (configure in ml/Taskfile if needed)
- Flutter: Flutter test framework (`flutter test`)

## Common Tasks

### Adding a new API endpoint
1. Update OpenAPI spec in `backend/api/backend/v1/backend.openapi.yaml`
2. Run `task backend:gen` to generate server stubs
3. Implement handler in `backend/internal/handler/`
4. Wire up in `backend/cmd/app/main.go`

### Adding a new ML feature
1. Modify `ml/main.py` to add new endpoint or modify OCR processing
2. Update Dockerfile if new dependencies needed
3. Test locally with `uvicorn main:app --reload`

### Making UI changes
1. Work in `/app/lib/` directory
2. Use `flutter run` for hot reload during development
3. Follow existing Riverpod architecture patterns

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running (check with `docker compose ps postgres`)
- Verify connection settings in `.env` file
- Check migration status with migration command

### ML Service Issues
- Check logs with `docker compose logs ml`
- First run may take time to download PaddleOCR model (~150MB)
- Verify port mapping: host:8001 -> container:8000

### Backend Issues
- Check logs with `docker compose logs backend`
- Verify ML service is reachable from backend (ML_HOST=ml in docker-compose)
- Check database connectivity

## Getting Help

Refer to:
- README.MD for general project overview
- README_RU.md for Russian documentation
- Individual service READMEs (if present) in each directory
- Code comments and docstrings throughout the codebase