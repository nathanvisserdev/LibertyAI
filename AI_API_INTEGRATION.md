# Interfacing with AI APIs

## Overview

This guide provides a comprehensive overview of how to integrate and interact with AI APIs in your applications. Whether you're working with OpenAI, Anthropic, Google AI, or other providers, many concepts remain consistent across platforms.

## Common Components

### Authentication

Most AI APIs require authentication via API keys:

```javascript
// Example: Setting up authentication
const apiKey = process.env.AI_API_KEY;
const headers = {
  'Authorization': `Bearer ${apiKey}`,
  'Content-Type': 'application/json'
};
```

**Best Practices:**
- Store API keys in environment variables, never in source code
- Use different keys for development, staging, and production
- Rotate keys regularly
- Implement key management systems for team projects

### Request Structure

AI API requests typically include:

1. **Model Selection**: Specify which AI model to use
2. **Messages/Prompts**: The input text or conversation history
3. **Parameters**: Configuration options (temperature, max tokens, etc.)
4. **System Instructions**: Optional context or behavioral guidelines

```json
{
  "model": "gpt-4",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What is machine learning?"}
  ],
  "temperature": 0.7,
  "max_tokens": 500
}
```

## Key Parameters

### Temperature
- Range: 0.0 to 2.0 (typically 0.0 to 1.0)
- Lower values (0.0-0.3): More deterministic, focused responses
- Higher values (0.7-1.0): More creative, varied responses

### Max Tokens
- Controls the maximum length of the response
- Each token ≈ 4 characters in English
- Consider input + output token limits

### Top P (Nucleus Sampling)
- Alternative to temperature
- Range: 0.0 to 1.0
- Controls diversity via probability mass

### Frequency/Presence Penalty
- Reduces repetition in responses
- Range: -2.0 to 2.0
- Positive values discourage repetition

## Implementation Patterns

### Basic HTTP Request

```python
import requests
import json

def call_ai_api(prompt, model="gpt-3.5-turbo"):
    url = "https://api.openai.com/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "max_tokens": 1000
    }
    
    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()
    
    return response.json()["choices"][0]["message"]["content"]
```

### Streaming Responses

```javascript
async function streamAIResponse(prompt) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      stream: true,
    }),
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    
    const chunk = decoder.decode(value);
    const lines = chunk.split('\n').filter(line => line.trim());
    
    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = line.slice(6);
        if (data === '[DONE]') continue;
        
        const parsed = JSON.parse(data);
        const content = parsed.choices[0]?.delta?.content;
        if (content) {
          process.stdout.write(content);
        }
      }
    }
  }
}
```

### Error Handling

```python
import time
from requests.exceptions import RequestException

def call_api_with_retry(prompt, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = call_ai_api(prompt)
            return response
        except RequestException as e:
            if attempt == max_retries - 1:
                raise
            
            # Handle rate limits
            if e.response.status_code == 429:
                wait_time = 2 ** attempt  # Exponential backoff
                time.sleep(wait_time)
            # Handle server errors
            elif e.response.status_code >= 500:
                time.sleep(1)
            else:
                raise
```

## Conversation Management

### Maintaining Context

```javascript
class ConversationManager {
  constructor() {
    this.messages = [];
  }

  addSystemMessage(content) {
    this.messages.push({ role: 'system', content });
  }

  addUserMessage(content) {
    this.messages.push({ role: 'user', content });
  }

  addAssistantMessage(content) {
    this.messages.push({ role: 'assistant', content });
  }

  async sendMessage(content) {
    this.addUserMessage(content);
    
    const response = await callAI({
      messages: this.messages,
      model: 'gpt-4',
    });
    
    this.addAssistantMessage(response);
    return response;
  }

  clearHistory() {
    this.messages = [];
  }
}
```

## Cost Management

### Token Counting

Estimate costs before making requests:

```python
import tiktoken

def count_tokens(text, model="gpt-4"):
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def estimate_cost(prompt, expected_response_tokens, model="gpt-4"):
    # Example pricing (check current rates)
    pricing = {
        "gpt-4": {"input": 0.03, "output": 0.06},  # per 1K tokens
        "gpt-3.5-turbo": {"input": 0.0015, "output": 0.002}
    }
    
    input_tokens = count_tokens(prompt, model)
    total_input_cost = (input_tokens / 1000) * pricing[model]["input"]
    total_output_cost = (expected_response_tokens / 1000) * pricing[model]["output"]
    
    return total_input_cost + total_output_cost
```

### Optimization Strategies

1. **Model Selection**: Use smaller models for simpler tasks
2. **Prompt Engineering**: Be concise and clear
3. **Caching**: Store common responses
4. **Rate Limiting**: Implement user quotas
5. **Batching**: Group similar requests when possible

## Security Considerations

### Input Sanitization

```python
def sanitize_input(user_input, max_length=4000):
    # Remove potentially harmful content
    sanitized = user_input.strip()
    
    # Limit length to prevent excessive costs
    if len(sanitized) > max_length:
        sanitized = sanitized[:max_length]
    
    return sanitized
```

### Output Validation

```python
def validate_output(response):
    # Check for sensitive information disclosure
    sensitive_patterns = [
        r'\b\d{3}-\d{2}-\d{4}\b',  # SSN
        r'\b\d{16}\b',  # Credit card
        # Add more patterns
    ]
    
    for pattern in sensitive_patterns:
        if re.search(pattern, response):
            return None  # Or filtered version
    
    return response
```

## Testing

### Unit Tests

```python
import unittest
from unittest.mock import patch, Mock

class TestAIIntegration(unittest.TestCase):
    @patch('requests.post')
    def test_api_call_success(self, mock_post):
        mock_response = Mock()
        mock_response.json.return_value = {
            "choices": [{"message": {"content": "Test response"}}]
        }
        mock_post.return_value = mock_response
        
        result = call_ai_api("Test prompt")
        self.assertEqual(result, "Test response")
    
    @patch('requests.post')
    def test_api_call_rate_limit(self, mock_post):
        mock_post.side_effect = RequestException(
            response=Mock(status_code=429)
        )
        
        with self.assertRaises(RequestException):
            call_ai_api("Test prompt")
```

## Monitoring and Logging

```python
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

def log_api_call(prompt, response, tokens_used, cost, duration):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "prompt_length": len(prompt),
        "response_length": len(response),
        "tokens_used": tokens_used,
        "cost": cost,
        "duration_ms": duration,
    }
    
    logger.info(f"API Call: {json.dumps(log_entry)}")
    
    # Store in database or analytics platform
    store_metrics(log_entry)
```

## Best Practices

1. **Rate Limiting**: Implement exponential backoff for retries
2. **Timeouts**: Set appropriate request timeouts
3. **Monitoring**: Track usage, costs, and performance
4. **Fallbacks**: Have backup strategies when APIs fail
5. **Version Control**: Pin API versions in production
6. **Documentation**: Keep track of prompt templates and configurations
7. **User Feedback**: Implement thumbs up/down for response quality
8. **Privacy**: Never log sensitive user information
9. **Compliance**: Follow data protection regulations (GDPR, CCPA)
10. **Testing**: Test with various inputs and edge cases

## Common Providers

### OpenAI
- Models: GPT-4, GPT-3.5-turbo, DALL-E, Whisper
- Endpoint: `https://api.openai.com/v1/`

### Anthropic
- Models: Claude 3 (Opus, Sonnet, Haiku)
- Endpoint: `https://api.anthropic.com/v1/`

### Google AI
- Models: Gemini Pro, PaLM
- Endpoint: `https://generativelanguage.googleapis.com/v1/`

### Azure OpenAI
- Same models as OpenAI, hosted on Azure
- Custom endpoints per deployment

## Resources

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic API Documentation](https://docs.anthropic.com)
- [Google AI Documentation](https://ai.google.dev/docs)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Token Counting Tools](https://platform.openai.com/tokenizer)

## Conclusion

Interfacing with AI APIs requires careful consideration of costs, security, performance, and user experience. Start simple, monitor your usage, and iterate based on real-world performance and feedback.
