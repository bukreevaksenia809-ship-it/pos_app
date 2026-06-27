import sys
import subprocess
import os

def check_python():
    try:
        import serial
        print("✅ pyserial installed")
        return True
    except ImportError:
        print("⚠️ pyserial not found")
        return False

def install_pyserial():
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
        print("✅ pyserial installed successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to install pyserial: {e}")
        return False

if __name__ == "__main__":
    if not check_python():
        install_pyserial()
