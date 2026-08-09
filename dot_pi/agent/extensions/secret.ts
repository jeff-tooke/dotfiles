/**
 * Secret Extension
 *
 * Provides a /secret command and a secret tool that call
 * ~/.local/bin/get-secret.sh to fetch secret values.
 *
 * Usage:
 *   /secret                  # fetch default secret
 *   /secret my-api-key       # fetch specific secret
 *
 * The secret tool can also be used by the agent:
 *   secret({ key: "my-api-key" })
 */

import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";

const SCRIPT_PATH = join(homedir(), ".local", "bin", "get-secret.sh");

export default function (pi: ExtensionAPI) {
	const secretTool = defineTool({
		name: "secret",
		label: "Secret",
		description: "Fetch a secret value from ~/.local/bin/get-secret.sh",
		parameters: Type.Object({
			key: Type.Optional(Type.String({ description: "Secret key name to retrieve" })),
		}),

		async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
			const args = params.key
				? [SCRIPT_PATH, params.key]
				: [SCRIPT_PATH];
			const result = await pi.exec("bash", args, { signal });
			const text = result.stdout?.trim() || result.stderr?.trim() || "(no output)";
			return {
				content: [{ type: "text", text }],
				details: { exitCode: result.code, key: params.key },
				isError: result.code !== 0,
			};
		},
	});

	pi.registerTool(secretTool);

	pi.registerCommand("secret", {
		description: "Fetch a secret via ~/.local/bin/get-secret.sh",
		handler: async (args, ctx) => {
			const key = args.trim();
			const bashArgs = key ? [SCRIPT_PATH, key] : [SCRIPT_PATH];
			const result = await pi.exec("bash", bashArgs);
			const text = result.stdout?.trim() || result.stderr?.trim() || "(no output)";
			ctx.ui.notify(text, result.code === 0 ? "info" : "error");
		},
	});
}
