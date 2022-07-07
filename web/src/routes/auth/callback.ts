import type {RequestHandler} from "@sveltejs/kit";
import * as cookie from 'cookie'
import {serverEndpoint} from "../../lib/constants";
import * as util from "util";

export const post: RequestHandler = async ({ request }): Promise<any> => {
    const form = await request.formData();

    const id_token = form.get('id_token');
    const refresh_token = form.get('refresh_token'); // todo use refresh token to renew id_token

    const res = await fetch(`${serverEndpoint}/user/me`, {
        method: 'GET',
        headers: new Headers({
            'Authorization': `Bearer ${id_token}`,
        }),
    });

    if (!res.ok) {
        console.log(`Could not validate token against backend ${util.inspect(await res.json())}`);
        return {
            status: res.status,
        }
    }

    const { id, firstName, lastName, isAdmin, email } = await res.json();

    return {
        status: 200,
        body: {
            user: {
                id: id,
                accessToken: id_token,
                firstName: firstName,
                lastName: lastName,
                isAdmin: isAdmin,
                email: email,
            },
        },
        headers: {
            'Set-Cookie': cookie.serialize('session', JSON.stringify(
                {
                    id: id,
                    accessToken: id_token,
                    firstName: firstName,
                    lastName: lastName,
                    isAdmin: isAdmin,
                    email: email,
                }), {
                path: '/',
                httpOnly: true,
                sameSite: 'strict',
                maxAge: 60 * 60 * 24 * 30,
            })
        }
    }
}