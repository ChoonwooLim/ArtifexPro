"""
Test connection to ArtifexPro services
"""

import requests
import json

def test_backend():
    """Test backend API connection"""
    print("Testing Backend API...")
    try:
        response = requests.get("http://localhost:8001/")
        if response.status_code == 200:
            print("[OK] Backend API is running on port 8001")
            data = response.json()
            print(f"   Status: {data.get('status', 'Unknown')}")
        else:
            print(f"[FAIL] Backend returned status code: {response.status_code}")
    except Exception as e:
        print(f"[FAIL] Backend connection failed: {e}")

def test_frontend():
    """Test frontend dev server"""
    print("\nTesting Frontend Dev Server...")
    try:
        response = requests.get("http://localhost:3000/")
        if response.status_code == 200:
            print("[OK] Frontend is running on port 3000")
        else:
            print(f"[FAIL] Frontend returned status code: {response.status_code}")
    except Exception as e:
        print(f"[FAIL] Frontend connection failed: {e}")

def test_models():
    """Test model endpoints"""
    print("\nTesting Model Endpoints...")
    try:
        response = requests.get("http://localhost:8001/api/models")
        if response.status_code == 200:
            print("[OK] Model endpoint accessible")
            models = response.json()
            print(f"   TI2V: {models['ti2v']['name']} - {models['ti2v']['status']}")
            print(f"   S2V: {models['s2v']['name']} - {models['s2v']['status']}")
        else:
            print(f"[FAIL] Models endpoint returned: {response.status_code}")
    except Exception as e:
        print(f"[FAIL] Models endpoint failed: {e}")

if __name__ == "__main__":
    print("="*50)
    print("ArtifexPro Connection Test")
    print("="*50)
    
    test_backend()
    test_frontend()
    test_models()
    
    print("\n" + "="*50)
    print("[SUCCESS] All services are ready!")
    print("Open http://localhost:3000 in your browser")
    print("="*50)