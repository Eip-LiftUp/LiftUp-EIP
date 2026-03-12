"""
Test script for I3D Video Analysis

Run this to test the video analysis endpoint:
    python test_i3d.py path/to/your/video.mp4
"""

import asyncio
import sys
import httpx
from pathlib import Path


async def test_health():
    """Test service health"""
    async with httpx.AsyncClient() as client:
        response = await client.get("http://localhost:8000/api/v1/video/health")
        print("=== Health Check ===")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        print()
        return response.status_code == 200


async def test_supported_exercises():
    """Get supported exercises"""
    async with httpx.AsyncClient() as client:
        response = await client.get("http://localhost:8000/api/v1/video/supported-exercises")
        print("=== Supported Exercises ===")
        data = response.json()
        print(f"Exercises: {', '.join(data['exercises'])}")
        print(f"Form aspects: {', '.join(data['form_aspects'])}")
        print()


async def test_video_analysis(video_path: str, exercise_type: str = None):
    """Test video analysis with an actual video"""
    path = Path(video_path)
    if not path.exists():
        print(f"Error: Video file not found: {video_path}")
        return
    
    print(f"=== Analyzing Video: {path.name} ===")
    print(f"File size: {path.stat().st_size / (1024*1024):.2f} MB")
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        with open(path, "rb") as f:
            files = {"video": (path.name, f, "video/mp4")}
            data = {}
            if exercise_type:
                data["exercise_type"] = exercise_type
            
            print("Uploading and analyzing...")
            response = await client.post(
                "http://localhost:8000/api/v1/video/analyze",
                files=files,
                data=data
            )
        
        if response.status_code == 200:
            result = response.json()
            print()
            print("=" * 50)
            print("ANALYSIS RESULTS")
            print("=" * 50)
            print(f"Quality Score: {result['quality_score']:.1f}/100")
            print(f"Detected Exercise: {result['detected_exercise']}")
            print(f"Confidence: {result['detection_confidence']:.1f}%")
            print()
            print("Form Scores:")
            for aspect, score in result['form_scores'].items():
                bar = "█" * int(score / 5) + "░" * (20 - int(score / 5))
                print(f"  {aspect.replace('_', ' ').title():20} [{bar}] {score:.1f}")
            print()
            print("Feedback:")
            for fb in result['feedback'][:5]:  # Show top 5
                icon = "✓" if fb['type'] == 'positive' else "!" if fb['type'] == 'correction' else "→"
                print(f"  {icon} [{fb['category']}] {fb['text']}")
            print()
            print(f"Processing time: {result['metrics']['processing_time_seconds']:.2f}s")
            print(f"Frames analyzed: {result['metrics']['frames_analyzed']}")
        else:
            print(f"Error: {response.status_code}")
            print(response.text)


async def main():
    print("=" * 60)
    print("I3D Video Analysis - Test Suite")
    print("=" * 60)
    print()
    
    # Test health
    healthy = await test_health()
    if not healthy:
        print("Service not healthy! Make sure it's running.")
        print("Run: cd server && uvicorn app.main:app --reload")
        return
    
    # Get supported exercises
    await test_supported_exercises()
    
    # If video path provided, test analysis
    if len(sys.argv) > 1:
        video_path = sys.argv[1]
        exercise_type = sys.argv[2] if len(sys.argv) > 2 else None
        await test_video_analysis(video_path, exercise_type)
    else:
        print("To test video analysis, run:")
        print("  python test_i3d.py path/to/video.mp4 [exercise_type]")
        print()
        print("Example:")
        print("  python test_i3d.py squat_video.mp4 squat")


if __name__ == "__main__":
    asyncio.run(main())
