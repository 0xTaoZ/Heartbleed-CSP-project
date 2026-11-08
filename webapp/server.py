import html
import os
import secrets
from http.cookies import SimpleCookie
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

HOST = "0.0.0.0"
PORT = 8080

DEMO_USER = os.environ.get("LAB_USER", "student@example.local")
DEMO_PASSWORD = os.environ.get("LAB_PASS", "heartbleed-lab")
# The real CTF flag is injected at runtime via LAB_FLAG (from the gitignored
# shared/secrets.env). This committed default is only a placeholder, so the
# real flag is never checked into the repository.
FLAG = os.environ.get("LAB_FLAG", "CTF_FLAG{PLACEHOLDER-set-LAB_FLAG-at-runtime}")

# In-memory storage simulating active server sessions on the heap
ACTIVE_SESSIONS = {}


def page(title, content):
  return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
  <style>
    body {{ background: #f1f3f5; color: #212529; font-family: Arial, sans-serif; margin: 0; }}
    main {{ background: white; border-radius: 8px; box-shadow: 0 3px 15px rgba(0,0,0,0.12); margin: 5rem auto; max-width: 520px; padding: 2rem; }}
    label {{ display: block; font-weight: bold; margin-top: 1rem; }}
    input {{ box-sizing: border-box; margin-top: 0.4rem; padding: 0.7rem; width: 100%; }}
    button {{ background: #1864ab; border: 0; border-radius: 4px; color: white; cursor: pointer; margin-top: 1.5rem; padding: 0.75rem 1.25rem; }}
    .error {{ background: #fff5f5; border-left: 4px solid #c92a2a; padding: 0.75rem; margin-top: 1rem; }}
    .success {{ background: #ebfbee; border-left: 4px solid #2b8a3e; padding: 0.75rem; margin-top: 1rem; }}
    code {{ background: #e9ecef; padding: 0.15rem 0.35rem; font-weight: bold; color: #d63384; }}
  </style>
</head>
<body>
  <main>{content}</main>
</body>
</html>
"""


def login_page(message=""):
  return page(
      "Heartbleed Lab Login",
      f"""
        <h1>Secure Corp Employee Portal</h1>
        <p>Sign in to load active session tokens and flags into server memory.</p>
        {message}
        <form method="post" action="/login">
          <label for="username">Email</label>
          <input id="username" name="username" type="email" required value="{DEMO_USER}">
          <label for="password">Password</label>
          <input id="password" name="password" type="password" required value="{DEMO_PASSWORD}">
          <button type="submit">Sign in to Dashboard</button>
        </form>
        """,
  )


class WebHandler(BaseHTTPRequestHandler):

  def send_html(self, content, status=200, headers=None):
    encoded = content.encode("utf-8")
    self.send_response(status)
    self.send_header("Content-Type", "text/html; charset=utf-8")
    self.send_header("Content-Length", str(len(encoded)))
    if headers:
      for k, v in headers.items():
        self.send_header(k, v)
    self.end_headers()
    self.wfile.write(encoded)

  def do_GET(self):
    if self.path == "/":
      self.send_html(login_page())
    elif self.path == "/health":
      self.send_html("ok", status=200)
    elif self.path == "/dashboard":
      cookies = SimpleCookie(self.headers.get("Cookie", ""))
      session_cookie = cookies.get("session")

      if (
          not session_cookie
          or session_cookie.value not in ACTIVE_SESSIONS
      ):
        self.send_html(
            login_page(
                '<div class="error">Unauthorized. Please sign in first.</div>'
            ),
            status=401,
        )
        return

      session_data = ACTIVE_SESSIONS[session_cookie.value]
      self.send_html(
          page(
              "Dashboard",
              f"""
                <h1>Welcome, {html.escape(session_data['user'])}</h1>
                <div class="success">Session Active & Authenticated!</div>
                <p>Your secret authentication token and flag are currently resident in runtime memory:</p>
                <p><code>{html.escape(session_data['flag'])}</code></p>
                <p><a href="/logout">Sign out</a></p>
                """,
          )
      )
    elif self.path == "/logout":
      cookies = SimpleCookie(self.headers.get("Cookie", ""))
      if "session" in cookies and cookies["session"].value in ACTIVE_SESSIONS:
        del ACTIVE_SESSIONS[cookies["session"].value]
      self.send_response(303)
      self.send_header("Location", "/")
      self.send_header(
          "Set-Cookie", "session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
      )
      self.end_headers()
    else:
      self.send_error(404)

  def do_POST(self):
    if self.path != "/login":
      self.send_error(404)
      return
    length = int(self.headers.get("Content-Length", 0))
    body = self.rfile.read(length).decode("utf-8")
    form = parse_qs(body)

    user = form.get("username", [""])[0]
    pwd = form.get("password", [""])[0]

    if user == DEMO_USER and pwd == DEMO_PASSWORD:
      # Generate a unique session token and store state in heap memory dictionary
      session_id = secrets.token_hex(16)
      ACTIVE_SESSIONS[session_id] = {
          "user": user,
          "flag": FLAG,
      }

      self.send_response(303)
      self.send_header("Location", "/dashboard")
      self.send_header(
          "Set-Cookie",
          f"session={session_id}; Path=/; HttpOnly; X-Session-Token={FLAG}",
      )
      self.end_headers()
    else:
      self.send_html(
          login_page('<div class="error">Invalid credentials.</div>'),
          status=401,
      )


if __name__ == "__main__":
  print(f"[*] Starting gamified webapp server on {HOST}:{PORT}...")
  ThreadingHTTPServer((HOST, PORT), WebHandler).serve_forever()