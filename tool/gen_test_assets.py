"""生成 M0 验收用样本 PDF。

用法：python tool/gen_test_assets.py
输出：test_assets/*.pdf
说明：样本全部程序生成，无版权问题，体积受控。
"""
import os
import random
import struct

from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfgen import canvas

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_assets")
CJK_FONT = "STSong-Light"

ZH_LINES = [
    "第一章 山间的清晨",
    "这是一段用于验证中文文本提取的正文内容，包含常用标点：，。！？；：“”‘’（）、",
    "第二行文字用于测试逐行矩形的稳定性，行与行之间保持固定行距。",
    "阅读器需要在不同缩放级别下保持标注与文字对齐，因此坐标必须归一化。",
    "本段包含数字 1234567890 与英文单词 PDF Reader Flutter pdfrx 混排。",
    "第三段用于验证跨行选择的矩形拆分是否正确，请配合划线测试使用。",
    "扫描件没有文字层，导入时应被识别并降级处理，不提供划线入口。",
    "目录跳转依赖 outline 解析结果，若缺失则降级为按页码跳转。",
]

EN_LINES = [
    "Chapter {n}: A Quiet Morning",
    "This paragraph validates line-level text extraction with character ranges.",
    "The reader stores normalized rectangles so highlights never drift when zooming.",
    "Numbers 0123456789 and mixed content PDF/Flutter/pdfrx appear here.",
    "A second paragraph checks multi-line selection splitting across lines.",
    "Scanned documents have no text layer and must degrade gracefully.",
    "Outline entries are resolved into page indices on first open.",
    "Long documents stress memory usage; rendering must stay on demand.",
]


def _register_fonts():
    pdfmetrics.registerFont(UnicodeCIDFont(CJK_FONT))


def _draw_lines(c, lines, width, height, font_size=14, leading=24):
    c.setFont(CJK_FONT, font_size)
    y = height - 80
    for line in lines:
        c.drawString(56, y, line)
        y -= leading
        if y < 60:
            break
    _ = width


def _make_text_pdf(path, pages, title, outline_levels=3, chinese=True, chapter_every=4):
    c = canvas.Canvas(path, pagesize=A4)
    c.setTitle(title)
    c.setAuthor("HomePdfReader")
    width, height = A4
    chapter = 0
    for i in range(pages):
        key = "page%d" % i
        c.bookmarkPage(key)
        if i % chapter_every == 0:
            chapter += 1
            if outline_levels >= 1:
                c.addOutlineEntry("第%d章 %s" % (chapter, title), key, level=0, closed=False)
            if outline_levels >= 2 and chapter % 2 == 0:
                c.addOutlineEntry("  %d.1 小节" % chapter, key, level=1, closed=False)
                if outline_levels >= 3 and chapter % 4 == 0:
                    c.addOutlineEntry("    %d.1.1 细节" % chapter, key, level=2, closed=False)
        body = []
        if chinese:
            body.append("第 %d 页 / 共 %d 页" % (i + 1, pages))
            body.extend(ZH_LINES)
        else:
            body.append("Page %d of %d" % (i + 1, pages))
            body.extend(line.format(n=chapter) for line in EN_LINES)
        _draw_lines(c, body, width, height)
        c.setFont(CJK_FONT, 9)
        c.drawString(56, 40, "HomePdfReader test asset - page %d" % (i + 1))
        c.showPage()
    c.save()


def _make_scanned_pdf(path, pages=6):
    from PIL import Image, ImageDraw, ImageFont

    font_path = r"C:\Windows\Fonts\msyh.ttc"
    font = ImageFont.truetype(font_path, 34) if os.path.exists(font_path) else ImageFont.load_default()
    tmp_dir = os.path.join(os.path.dirname(path), "_tmp")
    os.makedirs(tmp_dir, exist_ok=True)

    c = canvas.Canvas(path, pagesize=A4)
    width, height = A4
    for i in range(pages):
        img = Image.new("RGB", (1240, 1754), "white")
        d = ImageDraw.Draw(img)
        d.text((90, 110), "扫描版样本 第 %d 页" % (i + 1), font=font, fill=(20, 20, 20))
        for row in range(6):
            d.text((90, 220 + row * 90), "本页为图片，无文字层。用于验证降级提示。", font=font, fill=(40, 40, 40))
        img_path = os.path.join(tmp_dir, "scan_%d.jpg" % i)
        img.save(img_path, quality=55)
        c.drawImage(img_path, 0, 0, width=width, height=height)
        c.showPage()
    c.save()


def _make_broken(path):
    with open(path, "wb") as f:
        f.write(b"%PDF-1.7\n")
        f.write(os.urandom(2048))
        f.write(b"\n%%EOF\n")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    _register_fonts()
    _ = struct

    _make_text_pdf(os.path.join(OUT_DIR, "sample_text_en.pdf"), 12, "English Sample", 3, chinese=False)
    _make_text_pdf(os.path.join(OUT_DIR, "sample_text_zh.pdf"), 10, "中文样本", 3, chinese=True)
    _make_text_pdf(os.path.join(OUT_DIR, "sample_no_outline.pdf"), 8, "No Outline", outline_levels=0, chinese=True)
    _make_text_pdf(os.path.join(OUT_DIR, "sample_large.pdf"), 1200, "Large Sample", 2, chinese=False, chapter_every=40)
    _make_scanned_pdf(os.path.join(OUT_DIR, "sample_scanned.pdf"))
    _make_broken(os.path.join(OUT_DIR, "sample_broken.pdf"))

    for name in sorted(os.listdir(OUT_DIR)):
        p = os.path.join(OUT_DIR, name)
        if os.path.isfile(p):
            print("%-24s %8.1f KB" % (name, os.path.getsize(p) / 1024))


if __name__ == "__main__":
    random.seed(7)
    main()
