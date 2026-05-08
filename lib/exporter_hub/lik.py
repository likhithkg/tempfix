from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
import time

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))
driver.maximize_window()
wait = WebDriverWait(driver, 10)

try:
    # TC1 - Open Homepage
    driver.get("https://the-internet.herokuapp.com/")
    print("TC1 Passed: Homepage loaded")

    # TC2 - Click on Form Authentication
    form_auth_link = wait.until(EC.element_to_be_clickable(
        (By.LINK_TEXT, "Form Authentication")
    ))
    form_auth_link.click()
    print("TC2 Passed: Form Authentication page opened")

    # TC3 - Enter credentials
    username = wait.until(EC.presence_of_element_located((By.ID, "username")))
    username.send_keys("tomsmith")
    
    password = driver.find_element(By.ID, "password")
    password.send_keys("SuperSecretPassword!")
    print("TC3 Passed: Credentials entered")

    # TC4 - Click login
    login_btn = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
    login_btn.click()
    
    success_msg = wait.until(EC.presence_of_element_located(
        (By.CSS_SELECTOR, ".flash.success")
    ))
    print("TC4 Passed: Login successful")

    # TC5 - Logout
    logout_btn = wait.until(EC.element_to_be_clickable(
        (By.LINK_TEXT, "Logout")
    ))
    logout_btn.click()
    print("TC5 Passed: Logout successful")

except Exception as e:
    print(f"Error: {str(e)}")
    driver.save_screenshot("error.png")

finally:
    driver.quit()

    