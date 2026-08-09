/**
 * Ollama Provider Extension
 *
 * Overrides the Ollama provider base URL from the OLLAMA_BASE_URL
 * environment variable, falling back to the value in models.json if
 * the variable is not set.
 *
 * Usage:
 *   OLLAMA_BASE_URL=http://ollama.jefftooke.com:11434/v1 pi
 *
 * This allows the Ollama endpoint to be configured per-environment
 * without hard-coding it in models.json.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const envUrl = process.env.OLLAMA_BASE_URL?.trim();
	if (envUrl) {
		pi.registerProvider("ollama", {
			baseUrl: envUrl,
		});
	}
}
