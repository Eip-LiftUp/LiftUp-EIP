"""Video Scraping Module

This module handles video data collection from various sources
for ML model training.
"""

from app.scraping.video_scraper import VideoScraper
from app.scraping.config import ScraperConfig

__all__ = ["VideoScraper", "ScraperConfig"]
