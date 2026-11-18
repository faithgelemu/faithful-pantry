# Expiry-date OCR

Users can select or capture a grocery label photo, crop it and run OCR in the browser. Photo bytes are not uploaded to Firestore or to an OCR processing server through this workflow. The OCR library, worker and language resources do require external downloads.

## Supported formats

- `14/11/2026`, `14-11-26` and `14 11 26`
- `2027-03-27`
- `27 MAR 27` and `27 March 2027`
- `OCT 12` and `12 OCT`, with a current-year assumption notice
- `SEP 2028` and `05/2027`, with an assumed month-end date
- `BB: 05 27`, when associated with best-before wording

## How the parser works

The parser looks for supported date formats near recognised expiry labels and excludes dates clearly associated with recognised production or packing labels.

## Review before saving

OCR can misread dates or associate them with the wrong label, so users should check suggestions against the packaging. Confirming a suggestion fills the grocery form but does not save the item automatically.

Use-by and best-before dates have different meanings. The pantry model currently stores the selected date without a separate field for the label type.

## Limitations

- Glare, blur, low contrast and nearby batch or time codes can affect results.
- Cropping to the date and its wording can improve recognition.
- Unlabelled compact dates such as `141126` are unsupported.
- Ambiguous numeric dates use UK day/month/year order.
- Missing years use the current year, and month/year suggestions assume the last day of the month. Both show a notice.
- Automated tests do not establish OCR accuracy across every package, device or lighting condition.

See also `docs/ocr_experiment.md`.
