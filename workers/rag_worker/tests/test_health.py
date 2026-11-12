import json
from http.server import ThreadingHTTPServer
from pathlib import Path
import sys
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import urlopen

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from worker import Handler


class HealthTest(unittest.TestCase):
    def test_health_and_unknown_route(self):
        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = f"http://127.0.0.1:{server.server_port}"
            with urlopen(base + "/health") as response:
                self.assertEqual(json.load(response)["service"], "rag-worker")
            with self.assertRaises(HTTPError) as error:
                urlopen(base + "/missing")
            self.assertEqual(error.exception.code, 404)
        finally:
            server.shutdown()
            thread.join()
            server.server_close()


if __name__ == "__main__":
    unittest.main()
