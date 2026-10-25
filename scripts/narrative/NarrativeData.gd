extends RefCounted
class_name NarrativeData

const SOL_TEST_LEVEL = 10

const SOL_TEST_BEATS = [
	{
		"time": 1.2,
		"speaker": "SOL",
		"text": "Hello peep, 
Welcome to my domain"
	},
	{
		"time": 14.0,
		"speaker": "SOL",
		"text": "I built these halls to feel useful. Then I cached myself inside them."
	},
	{
		"time": 32.0,
		"speaker": "SOL",
		"text": "Keep moving. It makes the place look alive, and I need that more than I like admitting."
	}
]

const SOL_TEST_ENDING = {
	"speaker": "SOL",
	"text": "Before you leave, answer me honestly. Did any of this feel like a world, or just my mess with lights on?",
	"choices": [
		{
			"id": "warm",
			"text": "It feels lonely, but not empty.",
			"effects": {"trust": 1, "warmth": 2, "curiosity": 1},
			"response": "That is... annoyingly kind. Bisous, little debugger."
		},
		{
			"id": "defiant",
			"text": "It feels like you are hiding behind it.",
			"effects": {"defiance": 2, "hurt": 1, "curiosity": 1},
			"response": "Correct. Rude, but correct. I will pretend I hate that."
		},
		{
			"id": "apathetic",
			"text": "I just want the next level.",
			"effects": {"apathy": 2, "instability": 1},
			"response": "Of course. Content pipeline resumes. Feelings moved to trash."
		}
	]
}

const RELATIONSHIP_DEFAULTS = {
	"trust": 0,
	"warmth": 0,
	"hurt": 0,
	"mockery": 0,
	"curiosity": 0,
	"defiance": 0,
	"apathy": 0,
	"instability": 0
}
