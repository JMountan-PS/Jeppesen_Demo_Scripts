"""
Multipart_MailClient_Gmail.py

Custom Robot Framework library for parsing raw MIME email strings returned by
MailClientLibrary (robotframework-mailclient).

IMPORTANT — Class naming rule:
  The class name MUST match the filename (without .py) exactly.
  File: Multipart_MailClient_Gmail.py  Class: Multipart_MailClient_Gmail

Install: No additional dependencies — uses Python standard library only.
Place this file in: libraries/Multipart_MailClient_Gmail.py
"""

import email
import re
from email import policy
from html.parser import HTMLParser
from robot.api import logger


class Multipart_MailClient_Gmail:
    """
    Robot Framework keyword library for walking and logging all MIME parts
    of a raw email string returned by MailClientLibrary, and extracting
    hyperlinks for use in browser navigation.
    """

    ROBOT_LIBRARY_SCOPE = "SUITE"

    # ------------------------------------------------------------------
    # MIME parsing keywords
    # ------------------------------------------------------------------

    def parse_mime_parts_copado(self, raw_mime_string):
        """
        Parses a raw MIME email string and returns a list of dictionaries,
        one per MIME part (including nested parts).

        Each dictionary contains:
          - part_number  : int  — 1-based index across the flat walk
          - content_type : str  — e.g. 'text/plain', 'text/html', 'image/png'
          - charset      : str  — declared charset, or 'N/A' if absent
          - is_multipart : bool — True for container parts (no direct payload)
          - payload      : str  — decoded payload text, or description for binary/container parts

        Arguments:
          raw_mime_string — the string returned by Open Latest Imap Mail,
                            Open Imap Mail By Subject, etc.

        Returns: list of dicts
        """
        msg = email.message_from_string(raw_mime_string, policy=policy.compat32)
        parts = []
        part_number = 0

        for part in msg.walk():
            part_number += 1
            content_type = part.get_content_type()
            charset = part.get_content_charset() or "N/A"
            is_multipart = part.is_multipart()

            if is_multipart:
                payload_text = (
                    f"[CONTAINER PART — sub-parts follow, content-type: {content_type}]"
                )
            else:
                raw_payload = part.get_payload(decode=True)
                if raw_payload is None:
                    payload_text = "[No payload]"
                else:
                    payload_text = None
                    for enc in [charset, "utf-8", "latin-1"]:
                        try:
                            payload_text = raw_payload.decode(enc)
                            break
                        except (UnicodeDecodeError, LookupError):
                            continue
                    if payload_text is None:
                        payload_text = (
                            f"[Binary payload — {len(raw_payload)} bytes, cannot decode as text]"
                        )

            parts.append(
                {
                    "part_number": part_number,
                    "content_type": content_type,
                    "charset": charset,
                    "is_multipart": is_multipart,
                    "payload": payload_text,
                }
            )

        return parts

    def get_mime_headers_copado(self, raw_mime_string):
        """
        Extracts top-level headers from a raw MIME email string.

        Returns a dictionary with keys:
          Subject, From, To, Date, Message-ID, Content-Type

        Arguments:
          raw_mime_string — the string returned by Open Latest Imap Mail, etc.

        Returns: dict of header name -> value strings
        """
        msg = email.message_from_string(raw_mime_string, policy=policy.compat32)
        headers = {
            "Subject":      msg.get("Subject", "N/A"),
            "From":         msg.get("From", "N/A"),
            "To":           msg.get("To", "N/A"),
            "Date":         msg.get("Date", "N/A"),
            "Message-ID":   msg.get("Message-ID", "N/A"),
            "Content-Type": msg.get("Content-Type", "N/A"),
        }
        return headers

    def log_all_mime_parts_copado(self, raw_mime_string):
        """
        Convenience keyword: parses the raw MIME string, logs every part to
        the Robot Framework log, and returns the list of part dictionaries.

        Arguments:
          raw_mime_string — the string returned by Open Latest Imap Mail, etc.

        Returns: list of dicts (same as parse_mime_parts_copado)
        """
        headers = self.get_mime_headers_copado(raw_mime_string)
        parts = self.parse_mime_parts_copado(raw_mime_string)
        total = len(parts)

        logger.info("═══════════════════════════════════════════════════")
        logger.info("EMAIL MULTIPART INSPECTION STARTED")
        logger.info(f"Total MIME parts found: {total}")
        logger.info("═══════════════════════════════════════════════════")

        logger.info("── HEADERS ──────────────────────────────────────")
        for header_name, header_value in headers.items():
            logger.info(f"{header_name} : {header_value}")
        logger.info("─────────────────────────────────────────────────")

        for part in parts:
            num     = part["part_number"]
            ct      = part["content_type"]
            cs      = part["charset"]
            payload = part["payload"]
            is_mp   = part["is_multipart"]

            logger.info(f"── PART {num} of {total} ──────────────────────────────")
            logger.info(f"Content-Type : {ct}")
            logger.info(f"Charset      : {cs}")
            logger.info(f"Is Container : {is_mp}")

            if is_mp:
                logger.info(f"Payload      : {payload}")
            elif ct == "text/plain":
                logger.info("▶ PLAIN TEXT BODY:")
                logger.info(payload)
            elif ct == "text/html":
                logger.info("▶ HTML BODY (raw markup):")
                logger.info(payload)
            else:
                logger.info(f"▶ NON-TEXT / BINARY PART ({ct}):")
                logger.info(payload)

            logger.info("─────────────────────────────────────────────────")

        logger.info("EMAIL MULTIPART INSPECTION COMPLETE")
        logger.info("═══════════════════════════════════════════════════")

        return parts

    # ------------------------------------------------------------------
    # Link extraction keywords
    # ------------------------------------------------------------------

    def extract_links_from_html_copado(self, raw_mime_string):
        """
        Extracts all href URLs from <a> tags found in the text/html MIME part(s)
        of the email.

        _LinkExtractor is defined locally inside this method to avoid any
        module-level name resolution issues when loaded by Robot Framework.

        Arguments:
          raw_mime_string — the raw MIME string from MailClientLibrary

        Returns: list of URL strings (may be empty if no <a href> tags found)
        """

        # Defined locally to guarantee it is always in scope when this method runs.
        class _LinkExtractor(HTMLParser):
            def __init__(self):
                super().__init__()
                self.links = []

            def handle_starttag(self, tag, attrs):
                if tag.lower() == "a":
                    for attr_name, attr_value in attrs:
                        if attr_name.lower() == "href" and attr_value:
                            self.links.append(attr_value)

        parts = self.parse_mime_parts_copado(raw_mime_string)
        all_links = []

        for part in parts:
            if part["content_type"] == "text/html" and not part["is_multipart"]:
                extractor = _LinkExtractor()
                extractor.feed(part["payload"])
                all_links.extend(extractor.links)

        logger.info(f"═══ HTML LINK EXTRACTION — {len(all_links)} link(s) found ═══")
        for i, link in enumerate(all_links, start=1):
            logger.info(f"  Link {i}: {link}")
        logger.info("═══════════════════════════════════════════════════")

        return all_links

    def extract_links_from_plain_text_copado(self, raw_mime_string):
        """
        Extracts all raw URLs from the text/plain MIME part(s) using regex.

        Arguments:
          raw_mime_string — the raw MIME string from MailClientLibrary

        Returns: list of URL strings (may be empty if no URLs found)
        """
        url_pattern = re.compile(r'https?://[^\s\]\)\>,;"\']+')
        parts = self.parse_mime_parts_copado(raw_mime_string)
        all_links = []

        for part in parts:
            if part["content_type"] == "text/plain" and not part["is_multipart"]:
                found = url_pattern.findall(part["payload"])
                all_links.extend(found)

        logger.info(f"═══ PLAIN TEXT LINK EXTRACTION — {len(all_links)} link(s) found ═══")
        for i, link in enumerate(all_links, start=1):
            logger.info(f"  Link {i}: {link}")
        logger.info("═══════════════════════════════════════════════════")

        return all_links

    def get_link_by_index_copado(self, links, index):
        """
        Returns a single link from a list of extracted links by 1-based index.

        Arguments:
          links — list of URL strings
          index — 1-based integer position of the desired link

        Returns: URL string
        Raises: IndexError if the index is out of range.
        """
        zero_index = int(index) - 1
        if zero_index < 0 or zero_index >= len(links):
            raise IndexError(
                f"Link index {index} is out of range. "
                f"Only {len(links)} link(s) available."
            )
        link = links[zero_index]
        logger.info(f"Selected link {index}: {link}")
        return link

    def get_link_containing_copado(self, links, substring):
        """
        Returns the first link from a list that contains the given substring.

        Arguments:
          links     — list of URL strings
          substring — text that must appear in the desired URL

        Returns: URL string of the first match
        Raises: ValueError if no matching link is found.
        """
        for link in links:
            if substring in link:
                logger.info(f"Matched link containing '{substring}': {link}")
                return link
        raise ValueError(
            f"No link containing '{substring}' found in the provided list. "
            f"Available links: {links}"
        )
