"""CLI tool for managing video scraping

Usage:
    python -m app.scraping.cli --help
"""

import asyncio
import argparse
import json
import logging
from pathlib import Path

from app.scraping.video_scraper import VideoScraper
from app.scraping.config import ScraperConfig, VideoSourceConfig
from app.scraping.data_pipeline import DataPipeline

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config(config_path: str) -> ScraperConfig:
    """Load configuration from file"""
    config_file = Path(config_path)
    
    if config_file.exists():
        with open(config_file, 'r') as f:
            config_data = json.load(f)
        return ScraperConfig(**config_data)
    else:
        logger.warning(f"Config file {config_path} not found, using defaults")
        return ScraperConfig()


def save_config(config: ScraperConfig, config_path: str):
    """Save configuration to file"""
    config_file = Path(config_path)
    config_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(config_file, 'w') as f:
        json.dump(config.model_dump(), f, indent=2, default=str)
    
    logger.info(f"Configuration saved to {config_path}")


async def scrape_command(args):
    """Execute scraping"""
    config = load_config(args.config)
    
    # Enable sources if specified
    if args.enable_sources:
        for source_name in args.enable_sources:
            for source in config.sources:
                if source.name == source_name:
                    source.enabled = True
                    logger.info(f"Enabled source: {source_name}")
    
    # Check if any sources are enabled
    enabled_sources = [s for s in config.sources if s.enabled]
    if not enabled_sources:
        logger.error("No sources are enabled! Use --enable-sources or edit the config file.")
        return
    
    logger.info(f"Starting scraping with {len(enabled_sources)} enabled source(s)")
    
    # Create and run scraper
    scraper = VideoScraper(config)
    scraped_videos = await scraper.scrape_all_sources()
    
    logger.info(f"Scraping complete! Scraped {len(scraped_videos)} videos")
    
    # Print statistics
    stats = scraper.get_statistics()
    print("\n=== Scraping Statistics ===")
    print(json.dumps(stats, indent=2))


def stats_command(args):
    """Show dataset statistics"""
    config = load_config(args.config)
    pipeline = DataPipeline(config)
    
    stats = pipeline.get_statistics()
    
    print("\n=== Dataset Statistics ===")
    print(json.dumps(stats, indent=2))


def init_config_command(args):
    """Initialize a new configuration file"""
    config = ScraperConfig()
    
    # Customize based on arguments
    if args.output_dir:
        config.output_dir = Path(args.output_dir)
    
    if args.video_quality:
        config.video_quality = args.video_quality
    
    save_config(config, args.config)
    print(f"Initialized configuration at {args.config}")
    print("\nTo start scraping:")
    print("1. Edit the config file to add/enable video sources")
    print("2. Run: python -m app.scraping.cli scrape --enable-sources 'Workout YouTube'")


def split_dataset_command(args):
    """Split dataset into train/val/test"""
    config = load_config(args.config)
    pipeline = DataPipeline(config)
    
    train_ids, val_ids, test_ids = pipeline.split_dataset(
        train_ratio=args.train_ratio,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
        seed=args.seed,
    )
    
    print(f"Dataset split complete:")
    print(f"  Train: {len(train_ids)} videos")
    print(f"  Val: {len(val_ids)} videos")
    print(f"  Test: {len(test_ids)} videos")


def add_source_command(args):
    """Add a new video source to configuration"""
    config = load_config(args.config)
    
    # Create new source
    new_source = VideoSourceConfig(
        name=args.name,
        source_type=args.source_type,
        enabled=args.enabled,
        search_queries=args.queries,
        max_videos=args.max_videos,
    )
    
    config.sources.append(new_source)
    save_config(config, args.config)
    
    print(f"Added new source: {args.name}")


def main():
    parser = argparse.ArgumentParser(description="Video Scraping CLI")
    parser.add_argument(
        '--config',
        default='scraper_config.json',
        help='Path to configuration file'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Init command
    init_parser = subparsers.add_parser('init', help='Initialize configuration file')
    init_parser.add_argument('--output-dir', help='Output directory for scraped videos')
    init_parser.add_argument('--video-quality', choices=['360p', '480p', '720p', '1080p'], help='Video quality')
    
    # Scrape command
    scrape_parser = subparsers.add_parser('scrape', help='Start scraping videos')
    scrape_parser.add_argument(
        '--enable-sources',
        nargs='+',
        help='Names of sources to enable for this scraping session'
    )
    
    # Stats command
    stats_parser = subparsers.add_parser('stats', help='Show dataset statistics')
    
    # Split command
    split_parser = subparsers.add_parser('split', help='Split dataset into train/val/test')
    split_parser.add_argument('--train-ratio', type=float, default=0.8, help='Training set ratio')
    split_parser.add_argument('--val-ratio', type=float, default=0.1, help='Validation set ratio')
    split_parser.add_argument('--test-ratio', type=float, default=0.1, help='Test set ratio')
    split_parser.add_argument('--seed', type=int, default=42, help='Random seed')
    
    # Add source command
    add_source_parser = subparsers.add_parser('add-source', help='Add a new video source')
    add_source_parser.add_argument('--name', required=True, help='Source name')
    add_source_parser.add_argument('--source-type', required=True, choices=['youtube', 'web', 'local'], help='Source type')
    add_source_parser.add_argument('--queries', nargs='+', required=True, help='Search queries')
    add_source_parser.add_argument('--max-videos', type=int, default=100, help='Max videos to scrape')
    add_source_parser.add_argument('--enabled', action='store_true', help='Enable this source immediately')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # Execute command
    if args.command == 'init':
        init_config_command(args)
    elif args.command == 'scrape':
        asyncio.run(scrape_command(args))
    elif args.command == 'stats':
        stats_command(args)
    elif args.command == 'split':
        split_dataset_command(args)
    elif args.command == 'add-source':
        add_source_command(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
