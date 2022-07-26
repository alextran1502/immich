/// <reference types="@sveltejs/kit" />

// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
declare namespace App {
  interface Locals {
    user?: {
      id: string,
      email: string,
      firstName: string,
      lastName: string,
      isAdmin: boolean,
    }
  }

  // interface Platform {}

  interface Session {
    user?: import('./api/open-api').UserResponseDto
  }

  // interface Stuff {}
}

