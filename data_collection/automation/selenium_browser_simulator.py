"""
Selenium-based Web Browser Simulator
Generates realistic web browsing patterns
"""

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import time
import random
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BrowserSimulator:
    """Simulates realistic web browsing behavior"""
    
    def __init__(self):
        self.driver = None
        self.setup_driver()
    
    def setup_driver(self):
        """Setup Chrome driver with realistic settings"""
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.add_argument('--disable-blink-features=AutomationControlled')
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option('useAutomationExtension', False)
        
        # Add user agent
        options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
        
        try:
            self.driver = webdriver.Chrome(
                service=Service(ChromeDriverManager().install()),
                options=options
            )
            logger.info("Chrome driver initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Chrome driver: {e}")
            raise
    
    def browse(self, duration_minutes: int = 30):
        """Browse for specified duration"""
        sites = {
            'google': 'https://www.google.com',
            'github': 'https://www.github.com',
            'stackoverflow': 'https://www.stackoverflow.com',
            'microsoft': 'https://www.microsoft.com',
            'reddit': 'https://www.reddit.com',
            'youtube': 'https://www.youtube.com',
            'news': 'https://www.bbc.com/news',
            'tech': 'https://www.techcrunch.com'
        }
        
        end_time = time.time() + (duration_minutes * 60)
        
        while time.time() < end_time:
            try:
                site_name = random.choice(list(sites.keys()))
                site_url = sites[site_name]
                
                logger.info(f"Browsing to {site_name}")
                self.driver.get(site_url)
                
                # Wait for page load
                time.sleep(random.uniform(2, 5))
                
                # Simulate reading
                time.sleep(random.uniform(5, 15))
                
                # Perform site-specific actions
                if site_name == 'google':
                    self._google_search()
                elif site_name == 'github':
                    self._github_browse()
                elif site_name == 'stackoverflow':
                    self._stackoverflow_browse()
                
                # Scroll
                self._scroll_page()
                
                # Random delay before next site
                time.sleep(random.uniform(3, 8))
                
            except Exception as e:
                logger.error(f"Error during browsing: {e}")
                time.sleep(5)
    
    def _google_search(self):
        """Perform Google search"""
        try:
            search_box = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.NAME, "q"))
            )
            
            search_terms = [
                'python programming',
                'machine learning',
                'cybersecurity',
                'windows administration',
                'data science',
                'web development'
            ]
            
            term = random.choice(search_terms)
            search_box.clear()
            search_box.send_keys(term)
            time.sleep(random.uniform(1, 2))
            search_box.send_keys(Keys.RETURN)
            
            # Wait for results
            time.sleep(random.uniform(3, 8))
            
            # Click on a result sometimes
            if random.random() > 0.5:
                try:
                    results = self.driver.find_elements(By.CSS_SELECTOR, "h3")
                    if results:
                        random.choice(results[:5]).click()
                        time.sleep(random.uniform(5, 10))
                        self.driver.back()
                        time.sleep(2)
                except:
                    pass
                    
        except Exception as e:
            logger.debug(f"Google search failed: {e}")
    
    def _github_browse(self):
        """Browse GitHub"""
        try:
            # Scroll to see trending
            self.driver.execute_script("window.scrollTo(0, 500);")
            time.sleep(2)
            
            # Click on trending sometimes
            if random.random() > 0.7:
                try:
                    trending = self.driver.find_element(By.PARTIAL_LINK_TEXT, "Trending")
                    trending.click()
                    time.sleep(random.uniform(3, 8))
                except:
                    pass
        except Exception as e:
            logger.debug(f"GitHub browse failed: {e}")
    
    def _stackoverflow_browse(self):
        """Browse Stack Overflow"""
        try:
            # Click on questions
            questions = self.driver.find_elements(By.CSS_SELECTOR, ".question-summary")
            if questions:
                random.choice(questions[:5]).click()
                time.sleep(random.uniform(5, 10))
                self.driver.back()
                time.sleep(2)
        except Exception as e:
            logger.debug(f"Stack Overflow browse failed: {e}")
    
    def _scroll_page(self):
        """Simulate scrolling"""
        try:
            # Scroll down
            scroll_amount = random.randint(300, 1000)
            self.driver.execute_script(f"window.scrollBy(0, {scroll_amount});")
            time.sleep(random.uniform(1, 3))
            
            # Sometimes scroll back up
            if random.random() > 0.7:
                self.driver.execute_script(f"window.scrollBy(0, -{scroll_amount//2});")
                time.sleep(1)
        except:
            pass
    
    def close(self):
        """Close browser"""
        if self.driver:
            self.driver.quit()
            logger.info("Browser closed")


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Web Browser Simulator')
    parser.add_argument('--duration', type=int, default=30,
                       help='Duration in minutes (default: 30)')
    
    args = parser.parse_args()
    
    simulator = BrowserSimulator()
    
    try:
        simulator.browse(duration_minutes=args.duration)
    finally:
        simulator.close()


if __name__ == '__main__':
    main()


