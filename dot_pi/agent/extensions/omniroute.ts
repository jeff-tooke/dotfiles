/**
 * OmniRoute Provider Extension
 *
 * Registers a local OmniRoute LLM gateway as a pi model provider.
 * OmniRoute exposes an OpenAI-compatible API and routes requests to
 * configured upstream backends.
 *
 * Configuration (all via environment variables):
 *   OMNIROUTE_BASE_URL  - OmniRoute API base URL (default: http://localhost:8080/v1)
 *   OMNIROUTE_API_KEY   - API key for Bearer authentication
 *
 * Usage:
 *   # Start OmniRoute locally, then launch pi:
 *   OMNIROUTE_API_KEY=sk-... pi
 *
 *   # With a custom base URL:
 *   OMNIROUTE_BASE_URL=http://omniroute.local:3000/v1 OMNIROUTE_API_KEY=sk-... pi
 *
 * The extension dynamically discovers models from /v1/models at startup.
 * If discovery fails, it falls back to a minimal set of common models so
 * the provider remains usable.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface OmniRouteModel {
	id: string;
	object?: string;
	created?: number;
	owned_by?: string;
}

interface OmniRouteModelsResponse {
	object?: string;
	data?: OmniRouteModel[];
}

const DEFAULT_BASE_URL = "http://localhost:8080/v1";

function getBaseUrl(): string {
	const env = process.env.OMNIROUTE_BASE_URL?.trim();
	if (env) {
		// Strip trailing slash to normalise before appending /models
		return env.replace(/\/$/, "");
	}
	return DEFAULT_BASE_URL.replace(/\/$/, "");
}

function getApiKey(): string | undefined {
	return process.env.OMNIROUTE_API_KEY?.trim();
}

async function discoverModels(baseUrl: string, apiKey?: string): Promise<OmniRouteModel[]> {
	const headers: Record<string, string> = {
		Accept: "application/json",
	};
	if (apiKey) {
		headers["Authorization"] = `Bearer ${apiKey}`;
	}

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), 5000);

	try {
		const response = await fetch(`${baseUrl}/models`, {
			method: "GET",
			headers,
			signal: controller.signal,
		});

		if (!response.ok) {
			throw new Error(`OmniRoute returned HTTP ${response.status}: ${response.statusText}`);
		}

		const payload = (await response.json()) as OmniRouteModelsResponse;
		return payload.data ?? [];
	} finally {
		clearTimeout(timeout);
	}
}

function createModelConfig(model: OmniRouteModel) {
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
	const apiKey = getApiKey();

	let models: OmniRouteModel[] = [];
	let discoveryError: string | undefined;

	try {
		models = await discoverModels(baseUrl, apiKey);
	} catch (err) {
		discoveryError = err instanceof Error ? err.message : String(err);
	}

	const modelConfigs = models.length > 0
		? models.map(createModelConfig)
		: [
				// Fallback models when discovery fails or OmniRoute is not running
				{
					id: "default",
					name: "Default (OmniRoute)",
					reasoning: false,
					input: ["text"] as ("text" | "image")[],
					contextWindow: 128000,
					maxTokens: 16384,
					cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				},
			];

	pi.registerProvider("omniroute", {
		name: "OmniRoute",
		baseUrl,
		apiKey: "$OMNIROUTE_API_KEY",
		api: "openai-completions",
		authHeader: true,
		compat: {
			// OmniRoute is OpenAI-compatible; assume modern features
			supportsDeveloperRole: true,
			supportsReasoningEffort: true,
			supportsUsageInStreaming: true,
		},
		models: modelConfigs,
	});

	if (discoveryError) {
		// Non-fatal: provider is registered with fallback models
		console.warn(
			`[omniroute] Model discovery failed: ${discoveryError}. ` +
			`Provider registered with fallback models. ` +
			`Ensure OMNIROUTE_BASE_URL and OMNIROUTE_API_KEY are correct.`
		);
	} else if (models.length === 0) {
		console.warn(
			`[omniroute] No models returned by ${baseUrl}/models. ` +
			`Provider registered with fallback models.`
		);
	}
	// No output on success
}
