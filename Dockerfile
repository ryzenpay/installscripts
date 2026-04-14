FROM python:3.10

RUN useradd installscripts

COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt

WORKDIR /app

COPY app.py app.py
COPY templates/ templates/
COPY scripts/ scripts/

# Make scripts executable
RUN find scripts -name "*.sh" -type f -exec chmod +x {} \;

USER installscripts

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8000", "--access-logfile", "-"]