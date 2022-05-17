type AdminRegistrationResult = Promise<{
  error?: string
  success?: string
  user?: {
    email: string
  }
}>

type LoginResult = Promise<{
  error?: string
  success?: string
  user?: {
    accessToken: string
    firstName: string
    lastName: string
    isAdmin: boolean
    userId: string
    userEmail: string
  }
}>


export async function sendRegistrationForm(form: HTMLFormElement): AdminRegistrationResult {

  const response = await fetch(form.action, {
    method: form.method,
    body: new FormData(form),
    headers: { accept: 'application/json' },
  })

  return await response.json()
}


export async function sendLoginForm(form: HTMLFormElement): LoginResult {

  const response = await fetch(form.action, {
    method: form.method,
    body: new FormData(form),
    headers: { accept: 'application/json' },
  })

  return await response.json()
}
