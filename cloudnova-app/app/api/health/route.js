export const dynamic = "force-dynamic";

export async function GET() {
  return Response.json({
    status: "ok",
    uptime: Math.floor(process.uptime()),
    containers: 2,
    backups: 7,
    timestamp: new Date().toISOString(),
  });
}
