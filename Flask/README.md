مرحله  اول:
اینارو اول نصب کن 



pip install flask

pip install pyodbc

pip install python-dotenv



مرحله دوم:

فایل database.py (مهمترین فایل):

توی این فایل، اطلاعات اتصال به SQL Server رو باید عوض کنی:





DB\_CONFIG = {

&#x20;   'server': 'Mokhtari\\\\ReichSQL',    # ← این رو باید به اسم سرور خودت تغییر بدی

&#x20;   'database': 'HospitalDB',

&#x20;   'username': 'sa',                  # ← یوزرنیم خودت

&#x20;   'password': '\*\*\*\*\*\*\*\*',            # ← پسورد خودت

&#x20;   'driver': '{ODBC Driver 17 for SQL Server}',

&#x20;   'trust\_server\_certificate': 'yes'

}

مرحله سوم:



hospital-information-system-db/

│

├── app.py

├── database.py          ← این رو باید تغییر بدس

├── queries.py

├── functions.py

├── procedures.py

├── requirements.txt     ← این رو بسازی

│

├── templates/

│   ├── base.html

│   ├── index.html

│   ├── patients.html

│   ├── patient\_detail.html

│   ├── appointments.html

│   ├── beds.html

│   ├── lab\_results.html

│   ├── lab\_pending\_requests.html

│   ├── lab\_record\_result.html

│   ├── prescriptions.html

│   ├── prescriptions\_pending.html

│   ├── invoices.html

│   ├── iot\_devices.html

│   ├── alerts.html

│   ├── functions.html

│   ├── procedures.html

│   ├── doctor\_dashboard.html

│   ├── add\_medical\_record.html

│   ├── doctor\_prescribe.html

│   ├── doctor\_lab\_request.html

│   ├── new\_appointment.html

│   └── edit\_patient.html

│

└── static/

&#x20;   └── (اختیاری)

