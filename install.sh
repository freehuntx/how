#!/bin/bash

# Set the installation directory in the user's path
INSTALL_DIR="$HOME/.local/bin"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is required but not installed."
    echo "Please install Node.js first and then run this script again."
    exit 1
fi

# Check if xsel is installed (required for clipboard functionality)
if ! command -v xsel &> /dev/null; then
    echo "Warning: xsel is not installed. Clipboard functionality will not work."
    echo "To install xsel, run: sudo apt-get install xsel"
fi

# Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the scripts to the installation directory
echo "Installing scripts to $INSTALL_DIR..."

# Create the 'how' script
cat > "$INSTALL_DIR/how" << 'EOL'
#!/usr/bin/env node
const { spawnSync } = require('node:child_process')
const readline = require('node:readline')

const run = (command, args=[], options={}) => {
  const res = spawnSync(command, args, options)
  const stderr = res.stderr?.toString()
  const error = res.error
  
  if (error) { throw error }
  if (stderr) { throw stderr }
  return res.stdout?.toString() ?? ''
}

const ask = (question) => new Promise(resolve => {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
  rl.question(question, res => {
    rl.close()
    resolve(res)
  })
})

const prompt = `You must help answer a question. The question is most likely related to Linux
and bash. But it may also be a general question.
If its a general question just answer it as text using print tags like: <print>Your answer here</print>.
If you can provide a shell command that can be executed use execute tags like: <execute>echo "This is a bash command"</execute>
But prefer short, pregnant and precise answers.

Answer with correct tags! <print> tags for text output and <execute> tags for bash code output.

# Examples
<question>listen open ports</question>
<answer><execute>netstat -tulpn</execute></answer>

<question>whats the capital city of germany?</question>
<answer><print>berlin</print></answer>

<question>react hello world component</question>
<answer><print>function HelloWorld() {
  return <h1>Hello world</h1>
}</print></answer>

# Current question
<question>${process.argv.slice(2).join(' ').trim()}</question>
<answer>`

async function main() {
  const res = run('copilot_complete', [
    '--stop=</answer>',
    '--max_tokens=1000',
    prompt
  ]) || '<print>I cant help with that</print>'
  
  if (res.startsWith('<print>')) {
    console.log(res.replace(/<\/?print>/g, ''))
    process.exit(0)
  } else if (res.startsWith('<execute>')) {
    const command = res.replace(/<\/?execute>/g, '')
  
    console.log('Command:', command)
    const answer = (await ask('[c]opy/[e]xecute [C]:')) || 'c'

    if (answer === 'e') {
      console.log()
      run('bash', ['-c', command], { stdio: 'inherit' })
    } else {
      run('bash', ['-c', `echo -e ${JSON.stringify(command)} | xsel -b --trim`])
      console.log('Copied!')
    }
  } else {
    console.log(`Unknown response: ${res}`)
  }
}

main().catch(err => { throw err })
EOL

# Create the 'copilot_complete' script
cat > "$INSTALL_DIR/copilot_complete" << 'EOL'
#!/usr/bin/env node
const { homedir } = require('node:os')
const { existsSync, readFileSync, writeFileSync } = require('node:fs')

const COPILOT_TOKEN_PATH = homedir() + '/.config/copilot_token'

async function setup() {
  const client_id = "Iv1.b507a08c87ecfe98"
  const { device_code, user_code, verification_uri } = await fetch("https://github.com/login/device/code", {
    method: "POST",
    headers: {
      "accept": "application/json",
      "editor-version": "Neovim/0.6.1",
      "editor-plugin-version": "copilot.vim/1.16.0",
      "content-type": "application/json",
      "user-agent": "GithubCopilot/1.155.0",
      "accept-encoding": "gzip,deflate,br",
    },
    body: JSON.stringify({
      client_id,
      scope: "read:user"
    }),
  }).then(res => res.json())

  console.log(`Please visit ${verification_uri} and enter code ${user_code} to authenticate.`);

  while (true) {
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    const accessToken = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        "accept": "application/json",
        "editor-version": "Neovim/0.6.1",
        "editor-plugin-version": "copilot.vim/1.16.0",
        "content-type": "application/json",
        "user-agent": "GithubCopilot/1.155.0",
        "accept-encoding": "gzip,deflate,br",
      },
      body: JSON.stringify({
        client_id,
        device_code,
        grant_type: "urn:ietf:params:oauth:grant-type:device_code"
      }),
    })
      .then(res => res.json())
      .then(res => res.access_token)

    if (accessToken) {
      writeFileSync(COPILOT_TOKEN_PATH, accessToken);
      console.log("Authentication success!");
      break;
    }
  }
}

async function getToken() {
  let accessToken = ''

  if (!existsSync(COPILOT_TOKEN_PATH)) {
    await setup();
  }
    
  accessToken = readFileSync(COPILOT_TOKEN_PATH).toString()

  const { token, error_details } = await fetch("https://api.github.com/copilot_internal/v2/token", {
    headers: {
      "authorization": `token ${accessToken}`,
      "editor-version": "Neovim/0.6.1",
      "editor-plugin-version": "copilot.vim/1.16.0",
      "user-agent": "GithubCopilot/1.155.0"
    }
  }).then(res => res.json())
  
  if (error_details) throw new Error(error_details.message)

  return token
}

async function completeStream(prompt, options={}) {
  const token = await getToken()
  if (!token) throw new Error('Missing token')
    
  const completionsUrl = 'https://copilot-proxy.githubusercontent.com/v1/engines/copilot-codex/completions'
  const data = {
    prompt,
    suffix: '',
    max_tokens: 400,
    temperature: 0,
    top_p: 1,
    n: 1,
    stop: ['#', '---'],
    nwo: 'github/copilot.vim',
    stream: true,
    ...options
  }
  
  const res = await fetch(completionsUrl, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  })

  if (!res.body) throw new Error('Completion failed')

  let buffer = ''

  return res.body.pipeThrough(new TransformStream({
    transform(chunk, controller) {
      chunk = new TextDecoder().decode(chunk);
      buffer += chunk

      const lines = buffer.split('\n')
      buffer = lines.pop() || ''

      for (const line of lines) {
        if (!line) continue

        if (line.startsWith('data: {')) {
          try {
            JSON.parse(line.slice(6)).choices.forEach(({ text }) => {
              if (text === undefined) return
              
              controller.enqueue(text)
            })
          } catch (err) {}
        }
        else if (line === 'data: [DONE]') {}
        else {
          throw line
        }
      }
    }
  }))
}

function parseCli(default_options={}) {
  const cli = { command: undefined, options: { ...default_options } }
  const args = process.argv.slice(2)

  while (args.length) {
    const arg = args.shift()

    if (/^-?-[^-]/.test(arg)) {
      let [name, value] = arg.match(/^--?([^=]+)=?(.*)?$/)?.slice(1)
      if (!Object.hasOwn(default_options, name)) throw `Unknown option: ${name}`
      if (value === undefined) value = true
      if (/^-?\d+(.\d+)?$/.test(value)) value = parseInt(value)
      if (/^(true|false)$/i.test(value)) value = /^true$/i.test(value)
      cli.options[name] = value
    } else {
      cli.command = arg + ' ' + args.join(' ')
      break
    }
  }

  return cli
}

async function main() {
  const { command, options } = parseCli({
    max_tokens: 400,
    temp: 0,
    stop: undefined
  })
  
  if (!command) throw `[-] Please provide a prompt`
  if (options.stop) options.stop = options.stop.split(',').filter(Boolean).map(e => e.trim())

  const stream = await completeStream(command.trim(), options)
  const reader = stream.getReader();
  let result = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break
    process.stdout.write(value)
  }

  return result;
}

main().catch(console.error)
EOL

# Make the scripts executable
chmod +x "$INSTALL_DIR/how"
chmod +x "$INSTALL_DIR/copilot_complete"

# Add installation directory to PATH if not already present
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to PATH in .bashrc..."
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
    echo "Please restart your terminal or run 'source ~/.bashrc' to update your PATH."
fi

echo "Installation complete! You can now use the 'how' command in your terminal."