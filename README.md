# KhidmatYar: AI Service Orchestrator 🚀

> **Empowering the Informal Economy with Agentic AI**

KhidmatYar is an intelligent, end-to-end service matching and orchestration platform designed for the informal economy (plumbers, electricians, beauticians, tutors, etc.). It automates the entire lifecycle of a service request—from natural language understanding to provider discovery, matching, booking simulation, and follow-up—powered by **Google Antigravity (Gemini)**.

---

## 🌟 The Problem
The informal service sector heavily relies on WhatsApp messages, phone calls, and word-of-mouth referrals. This leads to:
- Inefficient service matching and delayed responses
- Difficulty in finding trusted, available, and nearby providers
- Zero automation for booking and status tracking

## 💡 Our Solution
KhidmatYar solves this by introducing a multi-agent AI system that:
1. **Understands Intent:** Parses multilingual requests (Urdu, Roman Urdu, English) naturally.
2. **Discovers Providers:** Finds relevant local providers using location and context.
3. **Smart Matching:** Ranks providers based on distance, rating, and availability using intelligent reasoning.
4. **Action Execution:** Simulates automated booking, scheduling, and receipts.
5. **Follow-Up Automation:** Schedules smart reminders and status updates.

---

## 🏗️ System Architecture

The project consists of three core layers, decoupled and integrated via REST APIs:

1. **`backend/` (FastAPI + CrewAI + Antigravity):** The brain of the operation. Orchestrates a 5-step agentic workflow using Google Gemini to handle NLP, reasoning, and database simulated bookings.
2. **`flutter-app/` (Mobile Client):** A cross-platform mobile application giving users a smooth, interactive chat-like interface to request services on the go.
3. **`web-frontend/` (Next.js):** A modern web application providing an accessible interface for service booking and agent trace visualization.

---

## 🛠️ Technology Stack
- **AI / Orchestration:** Google Antigravity (Gemini 1.5 Flash), CrewAI
- **Backend:** Python, FastAPI, SQLite
- **Mobile Frontend:** Flutter, Dart, Dio
- **Web Frontend:** Next.js, React, TailwindCSS

---

## 🚀 Getting Started

### Prerequisites
- Python 3.11+
- Node.js 18+
- Flutter SDK
- Google Gemini API Key

*(Detailed setup instructions for each component will be added during development)*

---
*Built for the Agentic AI Hackathon.*
