#!/usr/bin/env python3
"""
Jarvis Voice Demo - Simple interface with rounded corners
"""

import sys
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel
from PyQt6.QtCore import Qt, QTimer, QRectF
from PyQt6.QtGui import QFont, QPainter, QColor, QBrush, QPainterPath


class RoundedDemoWindow(QWidget):
    """Demo window with truly rounded corners"""

    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint
            | Qt.WindowType.WindowStaysOnTopHint
            | Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

        self.current_state = 0
        self.status_text = "🔴 Recording"
        self.bg_color = QColor(255, 59, 48, 230)  # Red

        # Window dimensions
        self.window_width = 320
        self.window_height = 42
        self.corner_radius = 21  # Half of height for perfect pill shape

        # Timer to cycle states
        self.state_timer = QTimer(self)
        self.state_timer.timeout.connect(self.cycle_state)
        self.state_timer.start(3000)

        # Position at top center
        screen = QApplication.primaryScreen().geometry()
        self.move((screen.width() - self.window_width) // 2, 100)

        self.resize(self.window_width, self.window_height)
        self.show()

    def paintEvent(self, event):
        """Draw rounded rectangle window"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        # Create rounded rectangle path
        path = QPainterPath()
        rect = QRectF(0, 0, self.window_width, self.window_height)
        path.addRoundedRect(rect, self.corner_radius, self.corner_radius)

        # Fill with background color
        painter.fillPath(path, QBrush(self.bg_color))

        # Draw text
        painter.setPen(QColor(255, 255, 255))
        font = QFont("SF Pro", 16, QFont.Weight.Bold)
        painter.setFont(font)

        # Center text
        text_rect = QRectF(0, 0, self.window_width, self.window_height)
        painter.drawText(text_rect, Qt.AlignmentFlag.AlignCenter, self.status_text)

        painter.end()

    def cycle_state(self):
        """Cycle through demo states"""
        states = [
            ("🔴 Recording", QColor(255, 59, 48, 230)),
            ("⚙️ Processing...", QColor(0, 122, 255, 230)),
            ("⌨️ Typing...", QColor(52, 199, 89, 230)),
            ("🎤 Ready", QColor(40, 40, 40, 230)),
        ]

        self.status_text, self.bg_color = states[self.current_state]
        self.current_state = (self.current_state + 1) % len(states)
        self.update()  # Redraw


def main():
    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    window = RoundedDemoWindow()

    print("=" * 60)
    print("🎤 Jarvis Voice Demo - Rounded Corners!")
    print("=" * 60)
    print("")
    print("Window size: 320×42 pixels")
    print("Corner radius: 21px (perfect pill shape)")
    print("")
    print("States (cycling every 3 seconds):")
    print("  1. 🔴 Recording (red)")
    print("  2. ⚙️ Processing (blue)")
    print("  3. ⌨️ Typing (green)")
    print("  4. 🎤 Ready (dark)")
    print("")
    print("✅ Notice: Window has curved/pill-shaped corners!")
    print("=" * 60)
    print("\nClose the window to exit.")

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
