//Kaj
namespace _3
{
	// Full colormask enum because UnityEngine.Rendering.ColorWriteMask doesn't have every option
	public enum ColorMask
	{
		None,
		Alpha,
		Blue,
		BA,
		Green,
		GA,
		GB,
		GBA,
		Red,
		RA,
		RB,
		RBA,
		RG,
		RGA,
		RGB,
		RGBA
	}

	// DX11 only blend operations
	public enum BlendOp
	{
		Add,
		Subtract,
		ReverseSubtract,
		Min,
		Max,
		LogicalClear,
		LogicalSet,
		LogicalCopy,
		LogicalCopyInverted,
		LogicalNoop,
		LogicalInvert,
		LogicalAnd,
		LogicalNand,
		LogicalOr,
		LogicalNor,
		LogicalXor,
		LogicalEquivalence,
		LogicalAndReverse,
		LogicalAndInverted,
		LogicalOrReverse,
		LogicalOrInverted
	}
}