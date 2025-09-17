#!/usr/bin/env python3
"""
Run the FastAPI server
Usage: python run_server.py
"""
import uvicorn
from main import app

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",  # Changed from 127.0.0.1 to accept connections from any IP
        port=8000,
        reload=True,
        log_level="debug"  # Set log level to debug for detailed logs
    )
