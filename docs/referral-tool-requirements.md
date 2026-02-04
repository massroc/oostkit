# Referral Process Tool Requirements

## Context

This tool supports Participative Design Workshops (PDW) using the referral-based participant selection process from Open Systems Theory (OST). The methodology comes from Merrelyn Emery's work. The goal is a reusable tool that can support this process for multiple engagements.

## The Referral Process

### Core Principle

The referral method is participative by nature — it lets the system identify its own participants rather than having them chosen by a single authority or expert. The people the system selects through this process are the right people.

### How It Works

1. Start with a known group (e.g. board and senior leaders)
2. Ask them to nominate others who should be involved in the workshop
3. Ask the nominated people who else should be there
4. Iterate through the network until the system surfaces its own participants
5. Multiple nominations for the same person (convergence) is the signal that someone should be included

### Key Constraints

- **Single-ask rule**: Each person is asked only once, regardless of how many nomination rounds run. If someone has been asked (whether they responded or not), they are excluded from subsequent rounds.
- **Target size**: A PDW typically has 15-25 participants.
- **Number of rounds**: Typically 3-4 rounds. First round from board/leaders, second round hits people who do the work, third catches the periphery, fourth is a check.

### Recommended Approach

Use the referral chain as the primary method (starting from board/leaders, iterating through), then do a single broader sweep at the end to catch people the network didn't reach. This gives peripheral or external people an opportunity to indicate they should be involved.

## Functional Requirements

### Core Features

- Collect and store nomination lists
- Count nominations (track convergence)
- Capture people not on the original list
- Track who has already been asked (enforce single-ask constraint)
- Support multiple rounds without asking the same person twice

### Facilitator Dashboard

- View nomination counts and convergence
- See who has been asked vs who hasn't responded
- Flag when approaching the target ceiling (~25 participants)
- Support decision-making without automating the decisions

### Participant Interface

- Web page linked from email
- Explain the process clearly
- Collect nominations
- Allow nominating people not yet in the system

## Design Principles

### The Tool Supports, Not Decides

- Give facilitators information to make decisions
- Trust the people doing the work to make the decisions
- The tool facilitates; humans own the outcomes

### Preserve Network Signal

- Using the iterative network approach preserves relational information
- The hybrid approach (referral chain + final sweep) balances thoroughness with network fidelity

## Open Questions

- Exact convergence thresholds (facilitator judgment)
- How to handle the final "broader sweep" technically
- Whether to store/display "who nominated whom" beyond convergence counts
