/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.jsonc`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */
// Cloudflare Worker for automatic failover to static site
// Uses modern ES modules format with TypeScript

interface Env {
	// Define environment variables here if needed
	MAIN_SERVER_URL?: string;
	STATIC_SITE_URL?: string;
}

const MAIN_SERVER = 'https://mcleod-dynamic.samyak.me/';
const STATIC_FALLBACK = 'https://mcleod-pitch-detection.pages.dev/';
const HEALTH_CHECK_TIMEOUT = 1000;

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);
		const mainServerUrl = env.MAIN_SERVER_URL || MAIN_SERVER;
		const staticSiteUrl = env.STATIC_SITE_URL || STATIC_FALLBACK;

		try {
			// Try to reach the main server first
			const mainServerResponse = await fetchWithTimeout(
				`${mainServerUrl}${url.pathname}${url.search}`,
				{
					method: request.method,
					headers: request.headers,
					body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : undefined,
				},
				HEALTH_CHECK_TIMEOUT
			);

			// If main server responds successfully, return its response
			if (mainServerResponse.ok) {
				return mainServerResponse;
			}

			console.log(`Main server returned ${mainServerResponse.status}, falling back to static site`);
		} catch (error) {
			console.log(`Main server failed: ${error instanceof Error ? error.message : 'Unknown error'}, falling back to static site`);
		}

		// Fallback to static site
		try {
			const staticResponse = await fetch(`${staticSiteUrl}${url.pathname}${url.search}`, {
				method: request.method === 'POST' || request.method === 'PUT' || request.method === 'DELETE'
					? 'GET' // Convert non-GET requests to GET for static site
					: request.method,
				headers: {
					// Forward some headers but clean up others
					'User-Agent': request.headers.get('User-Agent') || '',
					'Accept': request.headers.get('Accept') || '',
					'Accept-Language': request.headers.get('Accept-Language') || '',
				},
			});

			// Add a header to indicate this is served from fallback
			const response = new Response(staticResponse.body, {
				status: staticResponse.status,
				statusText: staticResponse.statusText,
				headers: staticResponse.headers,
			});

			response.headers.set('X-Served-By', 'cloudflare-worker-fallback');
			response.headers.set('X-Fallback-Active', 'true');

			return response;
		} catch (error) {
			// If even the static site fails, return an error
			return new Response(
				JSON.stringify({
					error: 'Both main server and fallback are unavailable',
					timestamp: new Date().toISOString(),
				}),
				{
					status: 503,
					headers: {
						'Content-Type': 'application/json',
						'X-Served-By': 'cloudflare-worker-error',
					},
				}
			);
		}
	},
};

// Utility function to add timeout to fetch requests
async function fetchWithTimeout(
	url: string,
	options: RequestInit,
	timeoutMs: number
): Promise<Response> {
	const controller = new AbortController();
	const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

	try {
		const response = await fetch(url, {
			...options,
			signal: controller.signal,
		});
		clearTimeout(timeoutId);
		return response;
	} catch (error) {
		clearTimeout(timeoutId);
		throw error;
	}
}
