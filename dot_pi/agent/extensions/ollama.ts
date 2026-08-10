/**
 * Ollama Provider Extension
 *
 * Registers the Ollama server as a pi model provider. The base URL is
 * taken from the OLLAMA_BASE_URL environment variable (falling back to
 * a local default if unset). The `/v1` suffix is appended automatically
 * when missing, since Ollama's OpenAI-compatible API lives under `/v1`.
 *
 * Usage:
 *   OLLAMA_BASE_URL=http://ollama.jefftooke.com:11434 pi
 *
 * The extension dynamically discovers models from `{baseUrl}/v1/models`
 * at startup. If discovery fails, it falls back to a minimal placeholder
 * model so the provider remains visible and usable once the server is up.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface OllamaModel {
	id: string;
	object?: string;
	created?: number;
	owned_by?: string;
}

interface OllamaModelsResponse {
	object?: string;
	data?: OllamaModel[];
}

const DEFAULT_BASE_URL = "http://localhost:11434/v1";

/**
 * Normalise the configured base URL: strip trailing slashes, then ensure
 * the `/v1` OpenAI-compatible prefix is present (Ollama serves its
 * OpenAI API at `{host}/v1`).
 */
function normalizeBaseUrl(raw: string): string {
	const trimmed = raw.trim().replace(/\/+$/, "");
	return trimmed.endsWith("/v1") ? trimmed : `${trimmed}/v1`;
}

function getBaseUrl(): string {
	const env = process.env.OLLAMA_BASE_URL?.trim();
	return env ? normalizeBaseUrl(env) : DEFAULT_BASE_URL;
}

async function discoverModels(baseUrl: string): Promise<OllamaModel[]> {
	const headers: Record<string, string> = {
		Accept: "application/json",
	};

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), 5000);

	try {
		const response = await fetch(`${baseUrl}/models`, {
			method: "GET",
			headers,
			signal: controller.signal,
		});

		if (!response.ok) {
			throw new Error(`Ollama returned HTTP ${response.status}: ${response.statusText}`);
		}

		const payload = (await response.json()) as OllamaModelsResponse;
		return payload.data ?? [];
	} finally {
		clearTimeout(timeout);
	}
}

function createModelConfig(model: OllamaModel) {
	return {
		id: model.id,
		name: model.id,
		reasoning: false,
		input: ["text"] as ("text" | "image")[],
		contextWindow: 128000,
		maxTokens: 16384,
		cost: {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
		},
	};
}

export default async function (pi: ExtensionAPI) {
	const baseUrl = getBaseUrl();

	let models: OllamaModel[] = [];
	let discoveryError: string | undefined;

	try {
		models = await discoverModels(baseUrl);
	} catch (err) {
		discoveryError = err instanceof Error ? err.message : String(err);
	}

	const modelConfigs = models.length > 0
		? models.map(createModelConfig)
		: [
				// Fallback model when discovery fails or Ollama is not running
				{
					id: "default",
					name: "Default (Ollama)",
					reasoning: false,
					input: ["text"] as ("text" | "image")[],
					contextWindow: 128000,
					maxTokens: 16384,
					cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				},
			];

	pi.registerProvider("ollama", {
		name: "Ollama",
		baseUrl,
		// Ollama ignores the API key, but pi still gates models behind auth;
		// a dummy key keeps them visible in /model and --list-models.
		apiKey: "ollama",
		api: "openai-completions",
		compat: {
			// Ollama servers commonly reject the `developer` role and
			// `reasoning_effort`; send system messages and no effort param.
			supportsDeveloperRole: false,
			supportsReasoningEffort: false,
		},
		models: modelConfigs,
	});

	if (discoveryError) {
		// Non-fatal: provider is registered with fallback models
		console.warn(
			`[ollama] Model discovery failed: ${discoveryError}. ` +
			`Provider registered with fallback models. ` +
			`Ensure OLLAMA_BASE_URL is correct and Ollama is running.`
		);
	} else if (models.length === 0) {
		console.warn(
			`[ollama] No models returned by ${baseUrl}/models. ` +
			`Provider registered with fallback models.`
		);
	}
	// No output on success
}
