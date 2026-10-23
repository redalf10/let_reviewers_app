# JAA LET Reviewer

The app's reviewer content, quizzes, annotations, profile, and quiz history are stored or bundled on the device. The app does not require an account or a network connection for its study flows.

## Offline AI tutor

Open **Ask the offline AI Tutor** from the home screen to search the bundled study PDFs. The first search extracts PDF text and builds a local retrieval index; later searches reuse the index saved in the app's local support directory. Questions stay on-device. Answers show matching source passages with subject, part, and page citations.

The tutor currently uses local lexical relevance ranking and retrieval-augmented source excerpts. It does not run a generative language model or invent explanations, so it may not synthesize an answer when the source uses different wording. A bundled generative model would require adding an on-device inference runtime and model weights, which are not part of this app.
