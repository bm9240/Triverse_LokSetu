# 🛡️ Triverse LokSetu - AI-Powered Citizen Grievance Redressal System

Demo Video Link - 

An intelligent, automated complaint management platform that routes citizen grievances to appropriate departments and officers using AI, real-time SLA monitoring, and automatic escalation.

---

## 📋 Table of Contents
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Key Modules](#key-modules)

---

## ✨ Features

✅ **AutoGov Engine** - Intelligent complaint routing based on category, priority, officer workload  
✅ **GrievBot** - Conversational AI for natural language complaint filing (voice + text)  
✅ **Real-Time SLA Monitoring** - Automatic escalation on deadline breach with officer penalties  
✅ **Smart Filtering** - Categories capped at appropriate urgency (parks → Medium max)  
✅ **Proof Chain** - Immutable, blockchain-inspired audit trail with SHA-256 hashing  
✅ **Officer Dashboard** - Real-time workload, performance gamification, penalty tracking  
✅ **Admin Portal** - View pending/escalated/completed complaints, top performers  
✅ **Citizen Tracking** - Full transparency with proof chain, escalation reasons  
✅ **Multi-Language Support** - Groq API NLP for complaint structuring  
✅ **Offline-First** - Local storage with automatic cloud sync  

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart), Material Design 3 |
| **State** | Provider, StreamBuilder |
| **Database** | Firebase Firestore, Storage, Auth |
| **AI/LLM** | Groq API (Claude Sonnet 4.5) |
| **Voice** | Google Speech-to-Text, Text-to-Speech |
| **Vision** | Google Cloud Vision, ML Kit |
| **Location** | Google Maps API, Geolocator |
| **Storage** | SharedPreferences (local), Firebase (remote) |
| **Notifications** | FCM, Flutter Local Notifications |
| **Security** | Firebase Auth, Firestore Rules, TLS/HTTPS |

---

## 🏗️ Architecture

```
UI Layer (Flutter Screens)
    ↓
State Management (Provider)
    ↓
Service Layer (AutoGov, SLA, Escalation, Officers)
    ↓
Data Layer (Firestore, SharedPreferences, APIs)
    ↓
External Services (Firebase, Groq, Google)
```

---

## 📁 Project Structure

```
lib/
├── models/
│   ├── complaint.dart          # Complaint + ProofChainEntry
│   ├── officer.dart             # Officer profile + metrics
│   └── autogov_complaint.dart   # AutoGov decision
├── screens/
│   ├── admin_screen.dart        # Pending/escalated/resolved
│   ├── officer_screen.dart      # Assigned + proof upload
│   ├── citizen_screen.dart      # Complaint tracking
│   └── grievbot_screen.dart     # Conversational AI
├── services/
│   ├── decision_engine.dart     # Priority/SLA + smart filtering
│   ├── sla_escalation_handler.dart # Auto-escalation
│   ├── firestore_service.dart   # CRUD operations
│   ├── officers_firestore_service.dart # Officer assignment
│   └── groq_service.dart        # Groq API (NLP)
├── providers/
│   ├── complaint_provider.dart  # State management
│   └── user_provider.dart       # Auth state
└── main.dart
```

---

## 🚀 Quick Start

```bash
# Clone & setup
git clone https://github.com/bm9240/Triverse_LokSetu.git
cd Triverse_LokSetu/my_app

# Install dependencies
flutter pub get

# Configure Firebase (google-services.json, GoogleService-Info.plist)
# Set environment variables (GROQ_API_KEY, GOOGLE_MAPS_API_KEY)

# Run
flutter run
```

---

## 🔑 Key Modules

**1. AutoGov Decision Engine**
- Category → Department mapping
- Smart urgency filtering (safety=Critical; parks=Medium)
- Priority calculation (P1–P4)
- SLA assignment (P1=10 min; P2=2d; P3=5d; P4=14d)
- Officer assignment (lowest workload)

**2. SLA Monitoring & Escalation**
- 30–60s background check
- Auto-escalate on breach: `escalatedToHead=true`, penalty (-1), new 2-day deadline
- Citizen notification + orange banner
- Audit logging of all events

**3. Proof Chain (Immutable)**
- SHA-256 hashing (tamper detection)
- Complete edit history
- Accessible to officer/citizen/admin

**4. GrievBot Conversational AI**
- Voice (STT) or text input
- Groq NLP processing → structured complaint
- AutoGov routing + confirmation

**5. Officer Performance**
- `resolutionPoints` (+1 per completion)
- `penaltyPoints` (-1 per SLA breach)
- `activeComplaints` (real-time workload)
- `slaComplianceRate` (% on-time)

---

## 🔐 Security

- **Auth** → Firebase Auth (phone OTP, email/password)
- **Authorization** → Firestore Rules (role-based access)
- **Encryption** → HTTPS/TLS in transit, Google-managed at rest
- **Audit** → Complete logging of SLA events, escalations, status changes
- **Integrity** → SHA-256 hashing for proof chain

---

## 📱 User Flows

**Citizen**: File complaint → GrievBot structures → AutoGov assigns → Track real-time → View proof chain + escalation banner

**Officer**: Receive push → View assigned complaints → Add proof → Complete → View performance metrics

**Admin**: View pending/escalated/completed → Monitor SLA compliance → Check officer performance (top/needs-improvement)

---

## 🎯 Future Roadmap

- Multi-language UI
- Advanced analytics dashboard
- WhatsApp integration
- Citizen feedback/rating system
- Geofencing for location-based assignment

---

**Built with ❤️ to empower citizens and streamline governance.**