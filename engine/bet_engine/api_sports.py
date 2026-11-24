"""Client minimal pour API-Football (API-Sports). Offre gratuite : 100 requêtes/jour."""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = "https://v3.football.api-sports.io"


class ApiSportsClient:
    def __init__(self, key: str, pause: float = 6.5, max_calls: int = 60, sleeper=time.sleep):
        self.key = key
        self.pause = pause
        self.max_calls = max_calls
        self.sleeper = sleeper
        self.calls = 0
        self.errors: list[str] = []

    def get(self, endpoint: str, params: dict) -> dict | None:
        if self.calls >= self.max_calls:
            self.errors.append("limite de requêtes de sécurité atteinte")
            return None
        url = f"{BASE_URL}/{endpoint}?{urllib.parse.urlencode(params)}"
        request = urllib.request.Request(url, headers={"x-apisports-key": self.key})
        for attempt in range(2):
            self.calls += 1
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = json.load(response)
            except urllib.error.HTTPError as error:
                self.errors.append(f"{endpoint}: HTTP {error.code}")
                return None
            except (urllib.error.URLError, TimeoutError, ValueError) as error:
                self.errors.append(f"{endpoint}: {error}")
                return None
            finally:
                self.sleeper(self.pause)
            errors = data.get("errors")
            if errors:
                text = json.dumps(errors, ensure_ascii=False)[:200]
                if attempt == 0 and "rate" in text.lower():
                    self.sleeper(30)
                    continue
                self.errors.append(f"{endpoint}: {text}")
                return None
            return data
        return None
