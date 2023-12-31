#!/usr/bin/env python

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")

@app.get("/hello")
def hello():
    return {"message": "Hello, World!"}


@app.get("/up")
def up():
    return {"message": "Server is up."}


# TODO: setup htmx to use this route
@app.get("/get-video", response_class=HTMLResponse)
async def get_video(id, width=854, height=480):
    video_html = f"""
    <iframe width="{width}" height="{height}" src="https://www.youtube.com/embed/{id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    <p>This is a short description of the video.</p>
    """
    return video_html


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})
