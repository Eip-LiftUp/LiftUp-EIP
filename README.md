# 🏋️ LiftUp-EIP

LiftUp is a mobile weight-training coaching app with personalized workout programs, performance tracking, and nutrition management for goals like muscle gain, cutting, maintenance, or strength. Powered by a Rust logic engine, it adapts workouts using real results (loads, reps, difficulty, progress) with training/calorie recommendations.

## 🚀 Quick Start

### Start Everything with Docker Compose
```bash
./start.sh
```

**Services will be available at:**
- 🌐 **Flutter Web**: http://localhost:8090
- 🔧 **Backend API**: http://localhost:8080  
- 🗄️ **PostgreSQL**: localhost:5432

### Or manually:
```bash
docker-compose up --build
```

### Development Mode

**Backend (Rust/Axum):**
```bash
cd back
docker-compose up -d postgres  # PostgreSQL only
cargo run                       # Start backend
```

**Flutter (Web):**
```bash
cd client/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

**Flutter (Mobile):**
```bash
cd client/app
flutter run -d android  # or -d ios
```

## 🏗️ Architecture

```
LiftUp/
├── back/              # Backend API (Rust/Axum + PostgreSQL)
├── client/app/        # Frontend (Flutter)
├── docs/              # Complete documentation
├── docker-compose.yml # Full stack orchestration
├── start.sh          # Quick start script
└── test-integration.sh # Integration tests
```

## 📦 Tech Stack

- **Backend**: Rust, Axum, PostgreSQL, SQLx
- **Frontend**: Flutter, Riverpod, Dio, Freezed
- **Infrastructure**: Docker, Docker Compose, Nginx

## 📚 Documentation

### 📌 Recent Changes
- **[CHANGELOG](CHANGELOG.md)** - Track major architectural updates.

### Architecture
- **[Architecture & UML Diagrams (C4 Model)](docs/ARCHITECTURE_UML_C4_MODEL.md)** - Complete system architecture with Context, Container, and Component diagrams

### Project Documentation
- **[User Research & Functional Scope](docs/personas_and_functional_scope/USER_RESEARCH_AND_FUNCTIONAL_SCOPE.md)** - User personas, stories, and feature backlog
- **[Costing & Technical Sizing](docs/costing_and_technical_sizing/WORKSHOP_COSTING_AND%20_TECHNICAL_SIZING.md)** - Infrastructure costs and scalability analysis
- **[Technical State of the Art](docs/context_audit_and_compliance/TECHNICAL_STATE_OF_THE_ART.md)** - Technology landscape and competitive analysis
- **[Security & Legal Audit](docs/context_audit_and_compliance/SECURITY_AND_LEGAL_AUDIT.md)** - GDPR compliance and security assessment
- **[Accessibility Strategy](docs/context_audit_and_compliance/ACCESSIBILITY_STRATEGY.md)** - WCAG 2.1 / RGAA 4.1 compliance
- **[Risk Management](docs/impacts_risks_and_mitigation/RISK_MANAGEMENT.md)** - Risk identification and mitigation strategies
- **[Environmental Impact](docs/impacts_risks_and_mitigation/ENVIRONMENTAL_IMPACT.md)** - GreenIT and carbon footprint analysis
- **[Deployment & Resilience](docs/impacts_risks_and_mitigation/DEPLOYMENT_RESILIENCE.md)** - CI/CD and production deployment strategy

### Developer Documentation
- **[Backend Integration Guide](client/app/BACKEND_INTEGRATION.md)** - How to connect Flutter with the backend
- **[Integration Summary](INTEGRATION_SUMMARY.md)** - Overview of backend ↔️ frontend integration
- **[Backend README](back/README.md)** - Rust/Axum API documentation

## 🧪 Testing

### Test backend health:
```bash
curl http://localhost:8080/health
```

### Create a test user:
```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser","fitness_level":"beginner"}'
```

### Run integration tests:
```bash
./test-integration.sh
```

## 🔧 Common Commands

### Docker Compose
```bash
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f            # View logs
docker-compose logs -f backend    # View backend logs
docker-compose restart backend    # Restart backend
docker-compose ps                 # Check status
```

### Backend Development
```bash
cd back
cargo build                       # Build
cargo run                         # Run
cargo test                        # Test
cargo clippy                      # Lint
sqlx migrate run                  # Run migrations
```

### Flutter Development
```bash
cd client/app
flutter pub get                                              # Install deps
dart run build_runner build --delete-conflicting-outputs   # Generate code
flutter run -d chrome                                       # Run web
flutter run -d android                                      # Run Android
flutter analyze                                             # Analyze code
flutter test                                                # Run tests
```

## 🌍 Network Configuration

The Flutter app automatically configures the backend URL based on the platform:
- **Web**: `http://localhost:8080`
- **Android Emulator**: `http://10.0.2.2:8080`
- **iOS Simulator**: `http://localhost:8080`
- **Physical Device**: Use your local IP (e.g., `http://192.168.x.x:8080`)

## 🐛 Troubleshooting

### Port already in use
```bash
sudo lsof -i :8080  # Check what's using port 8080
docker-compose down # Stop all services
```

### Flutter Linux build error
```bash
# Install required dependencies
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

# Or use web instead
flutter run -d chrome
```

### Backend won't start
```bash
docker-compose logs backend    # Check logs
docker-compose restart backend # Restart
```

## 📄 License

Proprietary - EIP LiftUp 2026
