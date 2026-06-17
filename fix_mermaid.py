import re

filepath = r'd:\TA\Mobile-hutabulumejan\TA-10-26\sequence_diagrams_web.html'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []

for line in lines:
    stripped = line.strip()
    
    # Check if this is a mermaid message line (contains ->> or -->> with : message)
    is_message_line = False
    if ('->>') in stripped and ':' in stripped:
        # But NOT a participant/actor declaration
        if not stripped.startswith('participant') and not stripped.startswith('actor'):
            is_message_line = True
    
    # Also check alt/else lines and Note lines
    is_alt_line = stripped.startswith('alt ') or stripped.startswith('else ')
    is_note_line = stripped.startswith('Note over')
    
    if is_message_line or is_alt_line or is_note_line:
        # Replace & with "dan" and remove double quotes from the message portion
        line = line.replace('&', 'dan')
        # Remove double quotes but keep the line structure
        # We need to be careful - only remove quotes that are NOT part of participant alias
        # For message lines, quotes after the colon should be removed
        if is_message_line and ':' in line:
            colon_idx = line.index(':')  
            # Find the actual message colon (after >>)
            arrow_idx = line.find('>>')
            if arrow_idx >= 0:
                msg_colon_idx = line.index(':', arrow_idx)
                prefix = line[:msg_colon_idx+1]
                message = line[msg_colon_idx+1:]
                message = message.replace('"', '')
                line = prefix + message
        elif is_alt_line or is_note_line:
            line = line.replace('"', '')
    
    new_lines.append(line)

result = '\n'.join(new_lines)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(result)

print("Done! Fixed all & and quotes in message labels.")
