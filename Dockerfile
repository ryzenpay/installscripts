FROM python:3.10

RUN useradd installscripts

COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt

USER installscripts
WORKDIR /app

COPY app.py app.py
COPY templates/* templates/
COPY --chmod=0755 scripts/* scripts/

CMD ["gunicorn", "app:app", "-b", "0.0.0.0"]