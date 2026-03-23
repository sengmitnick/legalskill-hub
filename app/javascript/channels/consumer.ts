// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from '@rails/actioncable'

// Only create consumer when user is signed in to avoid unauthorized connection errors
const isSignedIn = document.body?.dataset?.userSignedIn === 'true'
export default isSignedIn ? createConsumer() : null
