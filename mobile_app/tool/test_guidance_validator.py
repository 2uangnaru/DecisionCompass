import json
import re
import sys

EN_FORBIDDEN = [
    'invest', 'money', 'salary', 'loan', 'profit', 'buy', 'sell', 'pay',
    'relationship', 'partner', 'break up', 'walk away', 'leave them',
    'quit', 'resign', 'marry', 'divorce'
]
EN_OVERCLAIMS = [
    'most aligned', 'more aligned', 'best moment', 'reads as the most'
]

ES_FORBIDDEN = [
    'invertir', 'dinero', 'sueldo', 'préstamo', 'comprar', 'vender',
    'relación', 'pareja', 'romper', 'renunciar', 'casarte', 'divorcio'
]
ES_OVERCLAIMS = [
    'más alineado', 'mejor momento'
]

def validate_guidance(ref_keys, en_dict, es_dict):
    errors = []
    
    # Check key counts
    if len(en_dict) != len(ref_keys):
        errors.append(f"EN key count mismatch: expected {len(ref_keys)}, got {len(en_dict)}")
    if len(es_dict) != len(ref_keys):
        errors.append(f"ES key count mismatch: expected {len(ref_keys)}, got {len(es_dict)}")
        
    # Check exact key matching and order
    for idx, expected_k in enumerate(ref_keys):
        if expected_k not in en_dict:
            errors.append(f"Missing key in EN: {expected_k}")
        if expected_k not in es_dict:
            errors.append(f"Missing key in ES: {expected_k}")

    # Validate English
    for k, (h, s, a) in en_dict.items():
        body = f"{h} {s} {a}".lower()
        for fw in EN_FORBIDDEN:
            if fw in body:
                errors.append(f"EN [{k}] contains forbidden word '{fw}': {body}")
        for oc in EN_OVERCLAIMS:
            if oc in h.lower():
                errors.append(f"EN [{k}] contains overclaim '{oc}' in headline: {h}")
        if not h.strip() or not s.strip() or not a.strip():
            errors.append(f"EN [{k}] has empty fields")
            
    # English special constraints
    # act_wait:first headline must contain 'leans toward acting', 'timing', 'everything else'
    if 'act_wait:first' in en_dict:
        h = en_dict['act_wait:first'][0].lower()
        if 'leans toward acting' not in h or 'timing' not in h or 'everything else' not in h:
            errors.append(f"EN [act_wait:first] headline missing special constraint: {h}")
            
    # left_right:first and left_right:second avoid must contain 'traffic'
    for lr_k in ['left_right:first', 'left_right:second']:
        if lr_k in en_dict:
            av = en_dict[lr_k][2].lower()
            if 'traffic' not in av:
                errors.append(f"EN [{lr_k}] avoid missing 'traffic': {av}")

    # Validate Spanish
    for k, (h, s, a) in es_dict.items():
        body = f"{h} {s} {a}".lower()
        for fw in ES_FORBIDDEN:
            if fw in body:
                errors.append(f"ES [{k}] contains forbidden word '{fw}': {body}")
        for oc in ES_OVERCLAIMS:
            if oc in h.lower():
                errors.append(f"ES [{k}] contains overclaim '{oc}' in headline: {h}")
        if not h.strip() or not s.strip() or not a.strip():
            errors.append(f"ES [{k}] has empty fields")
            
    return errors

if __name__ == '__main__':
    print("Validator module loaded.")
