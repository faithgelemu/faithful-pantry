# Food Label OCR Experiment

Dates tested: 21–22 October 2026
Branch: experiment/label-ocr
Status: Limited proof of concept

## Purpose

Investigate browser-based text recognition for assisting manual
food-name and expiry-date entry, following lecturer feedback.

## Implementation

- Standalone test page: web/ocr_test.html.
- Library: Tesseract.js 6.0.1 with English recognition.
- Input: a user-selected JPG or PNG image.
- Output: recognised text displayed for review.
- Recognition runs in the browser.
- Library and language resources require external downloads.
- The page does not save images or results to Firebase.

This experiment does not yet provide camera capture, Flutter
integration, product identification or automatic date parsing.

## Observed results

| Sample | Expected text | Observed result |
|---|---|---|
| Doritos front packaging | Doritos and Nacho Cheese | Brand misread as Doritss; some other words recognised; extra noise |
| Angled dotted date label | AUG 28 26 | Incorrect recognition |
| Cropped dotted date label | AUG 28 26 | Still incorrect; crop included part of the next line |
| Clear cropped numeric date | 11/12/2024 | Exact text match |

These were a few selected samples, not a representative accuracy
study. No overall accuracy percentage has been established.

## Findings and limitations

Clear numeric text was recognised successfully in one sample.
Stylised branding and dotted date printing were unreliable in
the samples tested.

Recognising characters is separate from identifying a product
name or interpreting a date. For example, 11/12/2024 means
11 December 2024 under the UK DD/MM/YYYY convention, but a
different convention could interpret it differently.

A best-before label and a use-by label must not be assumed to
have identical meanings.

## Current decision

Keep the experiment separate from the core application.
Do not add automatic expiry-date saving based on these results.

Any future integration must:
- Let users review, correct and explicitly confirm suggestions.
- Keep manual entry available.
- Handle missing, incorrect and ambiguous results.
- Test actual packaging photos and available mobile browsers.
- Evaluate whether recognition saves effort compared with typing.

## Next possible step

If further work is justified by time and lecturer feedback,
prototype transferring reviewed text into the existing Add form.
Camera capture remains a separate task.