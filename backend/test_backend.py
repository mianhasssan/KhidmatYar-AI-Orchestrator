import requests
import json

def test_request(message):
    url = "http://127.0.0.1:8000/api/request"
    data = {"message": message, "user_id": "test_user_001"}
    
    print(f"--- Testing Request: '{message}' ---")
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            print("\n[AI Response]:")
            print(result["ai_response"])
            print("\n[Agent Trace Logs]:")
            for log in result["trace_logs"]:
                print(f" - {log}")
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Connection Failed: {e}")

if __name__ == "__main__":
    # Test with Roman Urdu
    test_request("Mujhe kal subah G-13 mein plumber chahiye")
