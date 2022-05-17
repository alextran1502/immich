import type { RequestHandler } from '@sveltejs/kit';
import { serverEndpoint } from '$lib/constants';
import * as cookie from 'cookie'

type UserInfo = {
  accessToken: string;
  userId: string;
  userEmail: string;
  firstName: string;
  lastName: string;
  isAdmin: boolean;
}

export const post: RequestHandler = async ({ request }) => {
  const form = await request.formData();

  const email = form.get('email')
  const password = form.get('password')

  const payload = {
    email,
    password,
  }

  const res = await fetch(`${serverEndpoint}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload),
  })

  if (res.status === 201) {
    // Login success
    const authUser = await res.json() as UserInfo;

    return {
      status: 200,
      body: {
        user: {
          userId: authUser.userId,
          accessToken: authUser.accessToken,
          firstName: authUser.firstName,
          lastName: authUser.lastName,
          isAdmin: authUser.isAdmin,
          userEmail: authUser.userEmail
        },
        success: 'success'
      },
      headers: {
        'Set-Cookie': cookie.serialize('session', JSON.stringify({ userId: authUser.userId, accessToken: authUser.accessToken, firstName: authUser.firstName, lastName: authUser.lastName, isAdmin: authUser.isAdmin, userEmail: authUser.userEmail }), {
          // send cookie for every page
          path: '/',

          // server side only cookie so you can't use `document.cookie`
          httpOnly: true,

          // only requests from same site can send cookies
          // and serves to protect from CSRF
          // https://developer.mozilla.org/en-US/docs/Glossary/CSRF
          sameSite: 'strict',

          // set cookie to expire after a month
          maxAge: 60 * 60 * 24 * 30,
        })
      }
    }

  } else {
    return {
      status: 400,
      body: {
        error: 'Incorrect email or password'
      }
    }
  }


}