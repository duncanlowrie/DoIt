#!/usr/bin/env swift
import AppKit
import Foundation

// Renders a 1024x1024 PNG icon to the path given as arg 1.
// Design: rounded blue gradient square with a stylized checklist of three rows,
// the top row checked off and struck through, the other two pending.

let outPath = CommandLine.arguments.dropFirst().first ?? "icon_1024.png"
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fputs("no graphics context\n", stderr)
    exit(1)
}
ctx.setShouldAntialias(true)
ctx.setAllowsAntialiasing(true)
ctx.interpolationQuality = .high

// ---- Background: rounded square with vertical gradient ----
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let cornerRadius = size * 0.2237  // macOS Big Sur+ squircle ratio
let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

NSGraphicsContext.saveGraphicsState()
bgPath.addClip()
let gradient = NSGradient(colors: [
    NSColor(red: 0.42, green: 0.62, blue: 1.00, alpha: 1.0),
    NSColor(red: 0.16, green: 0.34, blue: 0.90, alpha: 1.0),
])!
gradient.draw(in: rect, angle: -90)
NSGraphicsContext.restoreGraphicsState()

// Subtle inner highlight at the top for a little depth
NSGraphicsContext.saveGraphicsState()
bgPath.addClip()
let highlight = NSGradient(colors: [
    NSColor(white: 1.0, alpha: 0.18),
    NSColor(white: 1.0, alpha: 0.0),
])!
highlight.draw(in: NSRect(x: 0, y: size * 0.55, width: size, height: size * 0.45), angle: -90)
NSGraphicsContext.restoreGraphicsState()

// ---- Checklist rows ----
// Layout: three evenly spaced rows, each with a checkbox on the left and a
// "text line" bar on the right. First row is checked and struck through.
let rowCount = 3
let rowHeight = size * 0.12
let rowSpacing = size * 0.07
let totalHeight = CGFloat(rowCount) * rowHeight + CGFloat(rowCount - 1) * rowSpacing
let topY = (size + totalHeight) / 2  // top of first row

let leftMargin = size * 0.18
let rightMargin = size * 0.14
let boxSize = rowHeight
let gap = size * 0.06
let barX = leftMargin + boxSize + gap
let barMaxX = size - rightMargin
let barHeight = rowHeight * 0.55

for i in 0..<rowCount {
    let rowTop = topY - CGFloat(i) * (rowHeight + rowSpacing)
    let rowBottom = rowTop - rowHeight
    let rowCenterY = (rowTop + rowBottom) / 2

    // Checkbox
    let boxRect = NSRect(x: leftMargin, y: rowBottom, width: boxSize, height: boxSize)
    let boxPath = NSBezierPath(roundedRect: boxRect, xRadius: size * 0.022, yRadius: size * 0.022)

    if i == 0 {
        // Filled checkbox with a white check
        NSColor.white.setFill()
        boxPath.fill()

        // Draw the checkmark in blue
        let check = NSBezierPath()
        let cx = boxRect.minX
        let cy = boxRect.minY
        check.move(to: NSPoint(x: cx + boxSize * 0.22, y: cy + boxSize * 0.52))
        check.line(to: NSPoint(x: cx + boxSize * 0.44, y: cy + boxSize * 0.30))
        check.line(to: NSPoint(x: cx + boxSize * 0.80, y: cy + boxSize * 0.70))
        check.lineWidth = size * 0.020
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        NSColor(red: 0.16, green: 0.34, blue: 0.90, alpha: 1.0).setStroke()
        check.stroke()
    } else {
        // Outlined checkbox
        NSColor(white: 1.0, alpha: 0.0).setFill()
        boxPath.fill()
        NSColor.white.setStroke()
        boxPath.lineWidth = size * 0.014
        boxPath.stroke()
    }

    // Text line bar
    let barWidth: CGFloat
    switch i {
    case 0: barWidth = (barMaxX - barX) * 0.85
    case 1: barWidth = (barMaxX - barX) * 1.00
    default: barWidth = (barMaxX - barX) * 0.70
    }
    let barRect = NSRect(
        x: barX,
        y: rowCenterY - barHeight / 2,
        width: barWidth,
        height: barHeight
    )
    let barPath = NSBezierPath(roundedRect: barRect, xRadius: barHeight / 2, yRadius: barHeight / 2)
    if i == 0 {
        NSColor(white: 1.0, alpha: 0.55).setFill()
    } else {
        NSColor.white.setFill()
    }
    barPath.fill()

    // Strikethrough on the completed row
    if i == 0 {
        let strike = NSBezierPath()
        strike.move(to: NSPoint(x: barRect.minX + barHeight * 0.2, y: rowCenterY))
        strike.line(to: NSPoint(x: barRect.maxX - barHeight * 0.2, y: rowCenterY))
        strike.lineWidth = size * 0.012
        strike.lineCapStyle = .round
        NSColor.white.setStroke()
        strike.stroke()
    }
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to encode PNG\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
