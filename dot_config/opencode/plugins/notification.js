/**
 * OpenCode plugin: Session notification
 * Sends a macOS notification when a session becomes idle (task completed)
 */
export const SessionNotificationPlugin = async ({ $ }) => {
  const notify = async (message, title, sound) => {
    const script = `display notification "${message}" with title "${title}" sound name "${sound}"`
    await $`osascript -e ${script}`
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("Session terminée", "OpenCode", "Glass")
      }

      if (event.type === "session.error") {
        await notify("Erreur dans la session", "OpenCode", "Basso")
      }

      if (event.type === "permission.asked") {
        await notify("Permission demandée", "OpenCode", "Ping")
      }
    },
  }
}
