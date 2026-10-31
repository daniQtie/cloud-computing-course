export const dynamic = "force-dynamic";

const members = [
  { name: "Daniel De Vera", role: "Lead Architect" },
  { name: "Vinzon Roi Macaraeg", role: "DevOps Engineer" },
  { name: "Charles Queriones", role: "Security Officer" },
  { name: "Princess Enriquez", role: "Database Administrator" },
  { name: "John Rex Ismael", role: "Automation Engineer" },
];

export async function GET() {
  return Response.json({ members, count: members.length });
}
