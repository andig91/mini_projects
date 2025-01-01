# README for Mileage and Fuel Consumption Script

## Overview

This script calculates fuel consumption and mileage differences from a Paperless API dataset and optionally sends updates via Telegram if there are changes compared to the previous run. It processes documents associated with correspondents, extracts custom field data, and performs calculations like fuel consumption averages.

---

## Features

1. **Fetch Data from Paperless API:**  
   Retrieves document data filtered by specific parameters (e.g., document types) and processes them.

2. **Custom Field Validation and Extraction:**  
   Ensures the existence and validity of custom fields (e.g., fuel liters and mileage) before processing.

3. **Calculations:**  
   - Calculates the mileage difference (`kilometerField_diff`).
   - Sums up fuel consumption (`literField_sum`).
   - Computes average fuel consumption (`Durchschnittsverbrauch`) in liters per 100 kilometers.

4. **Telegram Integration:**  
   Sends updates via Telegram if new data differs from the previous run.

5. **Data Storage:**  
   Stores the computed results for future comparisons in `lastdata.json`.

---

## Prerequisites

1. **Python Modules:**  
   Install the following libraries:
   ```bash
   pip install requests pyTelegramBotAPI
   ```

2. **API Tokens:**  
   - Paperless API Token
   - Telegram Bot Token
   - Telegram Chat ID (Receiver)

3. **File Structure:**  
   Ensure the following files exist in the script's directory:
   - `cred.json`: Contains API tokens and credentials.
   - ~~`lastdata.json`: Stores previously computed data for change detection.~~ It will be created with the first run.

4. **System Requirements:**  
   - A Paperless server accessible at `http://localhost:8000`.
   - Documents with specific `custom_fields`:
     - Field `2`: Represents fuel liters.
     - Field `3`: Represents mileage.
   - Or change it (see next section)  

---

## Configuration

1. **Credentials File (`cred.json`):**  
   Example format:
   ```json
   {
       "TELEGRAM_TOKEN": "your_telegram_token",
       "TELEGRAM_RECEIVER": "your_chat_id",
       "PAPERLESS_TOKEN": "your_paperless_api_token"
   }
   ```

2. **Correspondent Mapping:**  
   Update the `correspondent_names` dictionary for better readability:
   ```python
   correspondent_names = {
       1: "Andreas",
       2: "Sandra"
   }
   ```

3. **Custom Fields-Mapping:**  
   Change the id of your coustom_fields. (Inspect the response with browser-dev-tools)  
   ```
    literField = field_value(doc, 2)
    kilometerField = field_value(doc, 3)
   ```

4. **Server Address and filter:**  
   Change the url for your API-Call. (Inspect with browser-dev-tools)  
   In my case, it is an specific document type.
   ```
    url = "http://localhost:8000/api/documents/?page=1&page_size=250&ordering=-created&truncate_content=true&document_type__id__in=5"
   ```

---

## Usage

1. **Run the Script:**
   Execute the script in the directory where the required files are stored:
   ```bash
   python3 spritverbauch.py
   ```

2. **Expected Workflow:**
   - Fetches documents from the API.
   - Extracts and validates fields.
   - Groups documents by correspondents.
   - Performs calculations.
   - Compares results with previous data.
   - Sends a Telegram notification if changes are detected.
   - Updates `lastdata.json`.

---

## Output

- **Console Log:**  
  Displays detailed information about processed documents, including:
  - Liter and mileage values for each correspondent.
  - Mileage difference and total fuel consumption.
  - Average fuel consumption (liters per 100 km).

- **Telegram Message (if changes detected):**  
  Example:
  ```
  Andreas: Diff-Kilometer 300km Sum-Liter 25l
  Andreas: 8.33 l/100km
  ```

- **Updated `lastdata.json`:**  
  Stores the latest computation results.

---

## Error Handling

1. **Missing Custom Fields:**  
   Documents missing required custom fields (field `2` or field `3`) are skipped.

2. **API Errors:**  
   Ensure the `PAPERLESS_TOKEN` and API endpoint are correctly configured.

3. **Telegram Failures:**  
   Check `TELEGRAM_TOKEN` and `TELEGRAM_RECEIVER` values if messages fail to send.

---

## Notes

- **Special Case:** Documents with a `0` value for custom fields will also be excluded. Modify the `field_value` function if this behavior is undesired.

- **Script Directory:** The script changes the working directory to its location. Ensure all paths are relative to the script.

---

## License

This script is distributed under the MIT License. Use it at your own discretion.