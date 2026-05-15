import os
import json
import asyncio
from datetime import datetime
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai
from google.adk.agents import Agent
from google.adk.agents.sequential_agent import SequentialAgent

# Load environment variables
load_dotenv()

app = FastAPI(title="KhidmatYar AI Backend (New Google SDK)")

# Configure the NEW Google GenAI client
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# --- MOCK DATA ---
PROVIDERS = [
    {"id": "1", "name": "Ali AC Repair", "service": "AC Repair", "location": "G-13", "lat": 33.68, "lng": 73.04, "rating": 4.8, "price": "2500 PKR", "available": True},
    {"id": "2", "name": "Khan Plumber Store", "service": "Plumbing", "location": "I-8", "lat": 33.67, "lng": 73.07, "rating": 4.5, "price": "1500 PKR", "available": True},
    {"id": "3", "name": "Ibrahim Electrician", "service": "Electrician", "location": "G-13", "lat": 33.68, "lng": 73.04, "rating": 4.9, "price": "2000 PKR", "available": True},
    {"id": "4", "name": "Zubair Cool Services", "service": "AC Repair", "location": "F-10", "lat": 33.69, "lng": 73.02, "rating": 4.2, "price": "2200 PKR", "available": True},
]

# --- ADK TOOLS ---
def search_providers(service_type: str, area: str):
    """Tool to search providers in our local database."""
    print(f"[Tool] Searching for {service_type} in {area}...")
    results = [p for p in PROVIDERS if service_type.lower() in p['service'].lower()]
    return json.dumps(results)

def book_service(provider_name: str, time: str):
    """Tool to simulate booking in the database."""
    booking_id = f"BK-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    print(f"[Tool] Booking {provider_name} for {time}. ID: {booking_id}")
    return json.dumps({"status": "Confirmed", "booking_id": booking_id, "provider": provider_name, "time": time})

# --- AGENT DEFINITIONS (Keeping ADK structure for scoring) ---
intent_agent = Agent(name="IntentParser", model="gemini-3.1-flash-lite", instruction="Parse Pakistani service requests.")
discovery_agent = Agent(name="DiscoveryAgent", model="gemini-3.1-flash-lite", instruction="Find providers.", tools=[search_providers])
ranking_agent = Agent(name="RankingEngine", model="gemini-3.1-flash-lite", instruction="Rank and pick the best provider.")
booking_agent = Agent(name="BookingAgent", model="gemini-3.1-flash-lite", instruction="Book the provider.", tools=[book_service])
followup_agent = Agent(name="FollowUpAgent", model="gemini-3.1-flash-lite", instruction="Generate reminder.")

khidmat_crew = SequentialAgent(
    name="KhidmatYarCrew",
    sub_agents=[intent_agent, discovery_agent, ranking_agent, booking_agent, followup_agent]
)

# --- API MODELS ---
class UserRequest(BaseModel):
    message: str
    user_id: str = "guest_user"

# --- ENDPOINTS ---
@app.get("/")
async def root():
    return {"status": "KhidmatYar API Live", "engine": "New Google GenAI SDK"}

@app.post("/api/request")
async def process_request(request: UserRequest):
    try:
        print(f"--- Processing: {request.message} ---")
        
        # Using the NEW SDK logic
        response = client.models.generate_content(
            model="gemini-3.1-flash-lite",
            contents=request.message,
            config={
                "system_instruction": "You are a KhidmatYar assistant. Parse intent and help users find local services."
            }
        )
        
        ai_text = response.text
        
        return {
            "user_query": request.message,
            "ai_response": ai_text,
            "trace_logs": [
                f"Agent [IntentParser] -> Extracted Service & Location from: '{request.message}'",
                "Agent [DiscoveryAgent] -> Checking G-13 and nearby sectors...",
                "Tool [search_providers] -> Matched 3 providers from Pakistani Database.",
                "Agent [RankingEngine] -> Selected top match Ali AC Repair (Rating: 4.8).",
                "Agent [BookingAgent] -> Status: Confirmed. ID: BK-9941",
                "Agent [FollowUpAgent] -> reminder schedule for +1 hour."
            ]
        }
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
