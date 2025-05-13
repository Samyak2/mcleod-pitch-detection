### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> title = "McLeod's Pitch Detection Method"
#> date = "2025-05-13"
#> tags = ["audio", "music", "explorable"]
#> description = "An interactive exploration of McLeod's method for pitch detection in audio signals. I plan to use this for a guitar tuner!"
#> 
#>     [[frontmatter.author]]
#>     name = "Samyak Sarnayak"
#>     url = "https://samyak.me/"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ e803b848-84f0-45b4-a4d8-b49088c36915
using Plots, PlutoUI

# ╔═╡ f1602df0-ce3f-459a-98cc-8bb6d3d100a4
using FFTW

# ╔═╡ 2727c889-166f-4ff3-a66f-9ebf80069c08
using FileIO, HTTP

# ╔═╡ 65e51277-e7b3-4473-91ae-4c8524b906e9
using WAV, MusicProcessing

# ╔═╡ 91cf5fdb-32fc-42a3-8e31-084c3e6e10d3
@bind frequency PlutoUI.Slider(1:10; default=1)

# ╔═╡ 0156d327-2766-438c-b43e-248b58136cfa
frequency

# ╔═╡ 66e74997-aed5-4db3-9e66-fca024f3e00a
md"Frequency in number of samples is $(round(frequency * 10 * π * 2; digits=2))"

# ╔═╡ 308b7e30-90ea-4d77-bb9f-cf9bfe4076a1
@bind num_periods PlutoUI.Slider(2:20; default=10)

# ╔═╡ 8e9f6c05-b970-496e-8fc9-e25c18954211
num_periods

# ╔═╡ 5abddcfc-7391-4fd3-b19a-1395fbd3e3d5
window_periods = 3

# ╔═╡ a694da85-365f-4774-a17e-83d4b986f69d
window_size = Int64(round(frequency * 10 * π * 2 * window_periods))

# ╔═╡ cf319412-86e6-438f-bdf4-ee374dc1955d
# data with 0.1 interval and some padding
values = map(
	x -> sin(frequency * x),
	0:0.1:2 * num_periods * π
)

# ╔═╡ 113aea2a-f1f0-48b6-8b52-bb5a5c156fba
full_periods = map(x -> 2 * 10π * x, 0:num_periods)

# ╔═╡ 760e0e83-ca35-43e5-a5fd-e4855ce456ea
periods = map(x -> 2 * 10π * x, 0:window_periods)

# ╔═╡ 2e28b639-6170-48fe-bab9-01ab420d5b51
begin
	plot(values)
	vline!(full_periods; linecolor="#FF000034")
end

# ╔═╡ ac5ed299-9c8b-4b04-85e3-985f018df6e0
md"## Autocorrelation"

# ╔═╡ abdc100b-4daf-49db-b910-e3bfe710ee6f
md"### ACF Type I"

# ╔═╡ 131963c2-ff7f-4c8f-99c0-58b75d824eff
function autocorr1(τ, x, t, W)
	sum(j -> (x[j] * x[j + τ]), t:t+W-1) 
end

# ╔═╡ 9b9129ab-a8ea-4d42-9bf0-fc30af661593
autocorr1(0, values, 1, window_size)

# ╔═╡ f61328df-17b1-45cb-9c4e-d36d2a2174a8
begin
	plot(τ -> autocorr1(τ, values, 1, window_size), 0:window_size)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ a68371ba-c898-4605-b0cf-781b339c595f
md"### ACF Type II"

# ╔═╡ 945e4416-c0f2-46bf-a46d-d66b04676d90
function autocorr2(τ, x, t, W)
	sum(j -> (x[j] * x[j + τ]), t:t+W-1-τ; init=0.0) 
end

# ╔═╡ 27f61efa-daa6-41d8-ac29-307ee7da8f07
begin
	plot(τ -> autocorr2(τ, values, 1, window_size), 0:window_size)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 44e9953b-700b-4d59-be1e-d6b6e7a7a434
md"""
*Note*: the red line indicates period of the function. ACF shows maxima at periods.
"""

# ╔═╡ 6913e83e-4847-46bc-ad90-b7491940f651
md"""
*Note*: In ACF type II, there is a tapering effect. With zero padded data, both type I and type II give similar results.
"""

# ╔═╡ 5a6bfbea-90d9-482e-bb1f-490f03fe100d
md"## Square Difference Function"

# ╔═╡ 7ffeb5f6-1ef1-4644-bdc8-21d561fda663
md"### SDF Type I"

# ╔═╡ 763871bb-968e-461d-9ec4-b82d0f1bacb6
function sdf1(τ, x, t, W)
	sum(j -> (x[j] - x[j + τ])^2, t:t+W-1; init=0.0) 
end

# ╔═╡ 443797a1-eaa3-4b4b-8fed-531c02797715
begin
	plot(τ -> sdf1(τ, values, 1, window_size), 0:window_size)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ ed34dc0b-8fbe-4507-a4b6-b740caef0aa7
md"### SDF Type II"

# ╔═╡ 2f9c94e6-fffd-4052-82ce-56c30ae98700
function sdf2(τ, x, t, W)
	sum(j -> (x[j] - x[j + τ])^2, t:t+W-1-τ; init=0.0) 
end

# ╔═╡ 419c36fd-2e43-4325-ae3b-a126eb24a079
begin
	plot(τ -> sdf2(τ, values, 1, window_size), 0:window_size)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 014ad646-822a-45d3-b07a-2c75b537b3f5
md"""
*Note*: the red line indicates period of the function. SDF shows minima at periods.
"""

# ╔═╡ d3ed368e-0bd0-4349-8115-036a3d3c4ff1
md"## Normalized Square Difference Function"

# ╔═╡ f0283499-6cd1-45a0-823b-da17b9152729
md"This is $m_t(\tau)$"

# ╔═╡ c042d49f-18f8-4396-9f95-f3933f6aa910
function m(τ, x, t, W)
	sum(j -> x[j]^2 + x[j + τ]^2, t:t+W-1-τ; init=0.0) 
end

# ╔═╡ 39a3f283-dd5d-4db8-b475-4eeb4f2db8c7
begin
	plot(
		τ -> m(τ, values, 1, window_size),
		0:window_size
	)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ f1b8a4ce-009c-45c7-9375-5f8a01811697
function nsdf(τ, x, t, W)
	2 * autocorr2(τ, x, t, W) / m(τ, x, t, W)
end

# ╔═╡ 9d66347a-3dd2-4882-80f0-38fe2da9c6f3
begin
	plot(
		τ -> nsdf(τ, values, 1, window_size),
		0:window_size
	)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 7bf8c5f9-9087-431c-82c3-6cb798a5c6f7
md"### Symmetric SDF"

# ╔═╡ 4b14fdcf-f80d-4542-a03f-d7465c8b50ac
function sdf2_symmetric(τ, x, t, W)
	low_range = max(t-(W-τ)÷2, 1)
	high_range = min(t-1+(W-τ)÷2, length(x))
	sum(j -> (x[j] - x[j + τ])^2, low_range:high_range; init=0.0) 
end

# ╔═╡ b28f5d7c-8aab-43f2-940a-5487f46f8794
begin
	plot(τ -> sdf2_symmetric(τ, values, 1, window_size), 0:window_size)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 3df96ed5-cd1c-4ea0-aa79-92b363251728
md"I'm not sure what this does exactly. But I do notice that the peaks *look* symmetric compared to normal SDF Type II."

# ╔═╡ f849bef5-55fd-47ea-97e5-5b035fef8d8d
md"## Efficient Calculation of SDF

(skipping the peak picking algorithm for the next section)"

# ╔═╡ 62b3a61a-ce32-40d1-90c6-34f3bd3241bf
window_values = values[1:window_size]

# ╔═╡ 7e2858c2-4ef5-4338-8acb-1435eeddde69
w = length(window_values) ÷ 2

# ╔═╡ 200e747c-277f-44fc-a121-14468f9ec871
md"Step 1: zero pad the window by w=$(w)"

# ╔═╡ 52c07508-5aa0-4abb-ae3b-130b5690a10d
padded_values = map(
	x -> sin(frequency * x),
	[window_values; fill(0.0, w)]
)

# ╔═╡ 3085b046-71ad-47de-a9f7-d9477f520e84
begin
	plot(padded_values)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 27c2f914-5fc0-4233-9e45-c7d738ad8725
md"Step 2: take fft"

# ╔═╡ 6fe0bc99-1fca-484f-8d4e-3b3f42b12db4
fft_values = rfft(padded_values)

# ╔═╡ 47d03ef6-2273-4a32-b51b-cf07a20f4e82
begin
	plot(real(fft_values); label="real part (magnitude)")
	plot!(imag(fft_values); label="imaginary part (phase)")
end

# ╔═╡ 01d7af69-d97b-4e83-a452-7ab374f45804
md"Step 3: power spectral density"

# ╔═╡ d009cb3e-eada-45e6-bfe0-c682b11e9dc3
psd = abs2.(fft_values)

# ╔═╡ c78eb5af-b2b0-45da-b5cd-e381769c36bf
md"""In the paper they say "multiply the complex by its conjugate".

The conjugate of a complex number $(a + ib)$ is $(a - ib)$.

The product of them is $(a + ib)(a - ib) = a^2 + b^2$.

The absolute value (or magnitude) of a complex number is $\sqrt{a^2 + b^2}$. So what we need is the square of this, given by the `abs2` function.

This value "square of the magnitude of the FFT" is related (directly proportional) to the Power Spectral Density (PSD) of a signal.

For a better explanation of PSD, see [this video by Matlab](https://youtu.be/pfjiwxhqd1M).
"""

# ╔═╡ 2dd0fc03-80fb-49dc-bdd5-b5539dc07661
begin
	plot(psd; label="power spectral density")
end

# ╔═╡ 676373d9-48b0-479e-8ec0-11a49dbeae02
md"Step 4: take the inverse fourier transform"

# ╔═╡ a7926231-bfb6-4aaf-bd5c-c11fee9b605d
autocorr_values_raw = irfft(psd, 2 * length(psd) - 1)

# ╔═╡ f21abc4f-25b1-43ed-a2e3-45185c5595fa
begin
	# take half the values because it's mirrored (why?)
	autocorr_values = autocorr_values_raw[1:Int(round(length(autocorr_values_raw)/2))]
	plot(autocorr_values)
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 6141119b-0e10-4473-a862-9d8fd735a5a6
md"Wrapping all of this into a single function"

# ╔═╡ 107393b3-1efe-40aa-8529-e4e88c3c8a8c
function autocorr_fast(x)
	w = length(x) ÷ 2
	# step 1: zero pad the window by w
	padded_values = [x; fill(0.0, w)]
	# step 2: take fft
	fft_values = rfft(padded_values)
	# step 3: power spectral density
	psd = abs2.(fft_values)
	# step 4: inverse fft
	autocorr_values_raw = irfft(psd, 2 * length(psd) - 1)

	# take only half the values because it's mirrored on the right side
	# not sure why yet
	autocorr_values = autocorr_values_raw[1:Int(round(length(autocorr_values_raw)/3))]

	# the output is shifted by one sample. unshift it. (why?)
	autocorr_values = autocorr_values[2:length(autocorr_values)]

	autocorr_values
end

# ╔═╡ 4fb10cf7-aef4-41cd-8579-9febf5a6c56c
begin
	plot(τ -> autocorr2(τ, values, 1, window_size), 0:window_size; label = "old version")
	plot!(autocorr_fast(window_values); label = "fast version")
	# this plot should look the exact same as the previous one
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ c1b62417-c1e6-4068-9961-f57595135974
md"### Calculation of $m_t(\tau)$"

# ╔═╡ 4771b76b-45e9-4969-bca4-8823b742f486
md"""
Recall the definition of $m_t(\tau)$:

``
\begin{align}
m_t(\tau) &= \displaystyle\sum_{j=t}^{t+W-\tau-1}{\big(x^2_j + x^2_{j+\tau}\big)} \\ 
&= \displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_j} + \displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau}}
\end{align}
``

When ``\tau = 0``:

``
\begin{align}
m_t(0) &= \displaystyle\sum_{j=t}^{t+W-1}{x^2_j} + \displaystyle\sum_{j=t}^{t+W-1}{x^2_{j}} \\ 
&= 2\displaystyle\sum_{j=t}^{t+W-1}{x^2_j}
\end{align}
``

---

Recall the definition of auto-correlation ``r_t(\tau)``:

``
\begin{align}
r_t(\tau) &= \displaystyle\sum_{j=t}^{t+W-\tau-1}{x_j x_{j+\tau}}
\end{align}
``

So when ``\tau = 0``:

``
\begin{align}
r_t(0) &= \displaystyle\sum_{j=t}^{t+W-1}{x_j x_{j}} \\ 
&= \displaystyle\sum_{j=t}^{t+W-1}{x_j^2}
\end{align}
``

---

Going back to ``m_t(0)``:

``
\begin{equation}
\tag{initial value} \boxed{m_t(0) = 2r_t(0)}
\end{equation}
``

Now we will try to write ``m_t(\tau + 1)`` in terms of ``m_t(\tau)``:

``
\begin{align}
m_t(\tau + 1) &= \displaystyle\sum_{j=t}^{t+W-(\tau + 1)-1}{x^2_j} + \displaystyle\sum_{j=t}^{t+W-(\tau + 1)-1}{x^2_{j+\tau + 1}} \\ 
&= \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_j}\bigg) - x_{t+W-\tau-1}^2 + \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau + 1}}\bigg) - x_{t+W-\tau-1+\tau+1}^2
\end{align}
``

Let's look at this term specifically:

``
\begin{align}
\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau + 1}}
&= x^2_{t + \tau + 1} + x^2_{t + \tau + 2} + ... + x^2_{t + W -\tau - 1 + \tau + 1 - 1} + x^2_{t + W -\tau - 1 + \tau + 1} \\ 
&= x^2_{t + \tau + 1} + x^2_{t + \tau + 2} + ... + x^2_{t + W - 1} + x^2_{t + W}
\end{align}
``

We want to replace it with:

``
\begin{align}
\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau}}
&= x^2_{t + \tau} + x^2_{t + \tau + 1} + ... + x^2_{t + W -\tau - 1 + \tau - 1} + x^2_{t + W -\tau - 1 + \tau} \\ 
&= x^2_{t + \tau} + x^2_{t + \tau + 1} + ... + x^2_{t + W - 2} + x^2_{t + W - 1} \\ 
&= x^2_{t + \tau} + \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau + 1}}\bigg) - x^2_{t + W} \\ 
\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau + 1}} &= \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau}}\bigg) - x^2_{t + \tau} + x^2_{t + W}
\end{align}
``

Going back:

``
\begin{align}
m_t(\tau + 1) &= \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_j}\bigg) - x_{t+W-\tau-1}^2 + \bigg(\bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau}}\bigg) - x^2_{t + \tau} + x^2_{t + W}\bigg) - x_{t+W}^2 \\ 
&= \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_j}\bigg) - x_{t+W-\tau-1}^2 + \bigg(\displaystyle\sum_{j=t}^{t+W-\tau-1}{x^2_{j+\tau}}\bigg) - x^2_{t + \tau} \\ 
&= m_t(\tau) - x_{t+W-\tau-1}^2 - x^2_{t + \tau}
\end{align}
``

In other words,

``
\begin{equation}
\tag{subsequent values} \boxed{m_t(\tau) = m_t(\tau - 1) - x_{t+W-\tau-2}^2 - x_{t + \tau - 1}^2}
\end{equation}
``

Using these two equations, we can get the value of any ``m_t(\tau)`` by using the auto-correlation (`autocorr_values`) we calculated in the previous section.
"""

# ╔═╡ 563e5463-2c59-4393-bebf-50a9496f5e27
function m_fast(values, autocorr_values)
	W = length(values)
	t = 0
	
	m_values = Vector{Float64}(undef, length(autocorr_values))
	m_values[1] = 2 * autocorr_values[1]
	for τ in 2:length(autocorr_values)
		next_value = m_values[τ - 1] - (values[W - τ - 2])^2 - (values[τ - 1])^2
		m_values[τ] = max(next_value, 0)
	end

	m_values
end

# ╔═╡ cc13576f-c390-4836-9a57-9b5699782079
begin
	plot(
		τ -> m(τ, window_values, 1, length(window_values)),
		1:window_size
		; label="old version"
	)
	plot!(m_fast(window_values, autocorr_fast(window_values)); label="fast version")
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 25184836-19c3-46bf-978c-3495b7508fd0
function nsdf_fast(values)
	autocorr_values = autocorr_fast(values)
	return 2.0 * autocorr_values ./ (m_fast(values, autocorr_values))
end

# ╔═╡ e9c87223-73ce-4ce8-b19f-27d3c5103b58
begin
	plot(
		τ -> nsdf(τ, values, 1, window_size),
		0:window_size
		; label = "old version"
	)
	plot!(nsdf_fast(window_values); label = "fast version")
	vline!(periods; linecolor="#FF000034")
end

# ╔═╡ 78905af5-403d-4fc1-be2d-50d9e8307e85
md"## Peak picking algorithm"

# ╔═╡ 8f065ce4-550b-4dde-80e5-f37cc272e1dc
md"""Let's take a real audio sample for this one. It's a piano note. Specifically A3, which has a fundamental frequency of 220Hz."""

# ╔═╡ eb5280ac-bbf6-4637-bc13-6e6a0e0e0c1e
url = "https://github.com/parisjava/wav-piano-sound/raw/refs/heads/master/wav/a1.wav"

# ╔═╡ fb0df150-8948-4822-9893-17e30ae1d7a0
Resource(url)

# ╔═╡ fd6b9dfb-53b1-4269-a179-42ff58b1b9dd
audio_raw, sample_rate, _, _ = load(HTTP.URI(url))
# audio_raw, sample_rate, _, _ = load("/Users/samyak/Downloads/A4_2.wav")
# audio_raw, sample_rate, _, _ = load("example.wav")

# ╔═╡ 785e5b03-5486-4c57-8130-8aabfdb89993
audio_mono = mono(audio_raw)[10000:end]

# ╔═╡ 768a1d2a-a091-4276-a0fa-31c1841e70e9
md"The audio has a sample rate of $(Int(round(sample_rate)))Hz. Since there are $(length(audio_mono)) samples, we have data for $(round(Float64(length(audio_mono)/sample_rate); digits=3)) seconds."

# ╔═╡ 3135f531-bf5b-4a4a-819d-09974ec85145
plot(audio_mono)

# ╔═╡ c768b564-489f-45aa-ac7a-2a7adb5f70a2
md"The graph looks very messy. Let's zoom in a bit"

# ╔═╡ 03f071c5-d28e-4dd4-bdf9-a9f6bf24a744
window_size_audio = 4096

# ╔═╡ 71824aa1-1a7f-4afc-9a72-901be686c16a
md"From the paper:

> Typical window sizes we use for a 44100 Hz signal are 512, 1024, 2048 or 4096 samples
"

# ╔═╡ e8a9f572-c9a9-46d9-99c6-3f214d8e7639
plot(audio_mono[window_size_audio:window_size_audio*2])

# ╔═╡ 268b6cf5-0cc7-4282-afcb-151fa65c6acf
md"There is some wave in there!

Let's try auto-correlation on it."

# ╔═╡ aae1b32b-8f2b-46a7-9268-c25e2293bf02
plot(autocorr_fast(audio_mono[1:window_size_audio]))

# ╔═╡ 12c5ae51-fe2d-4758-916b-e8d8f54db529
sample_rate / (argmax(autocorr_fast(audio_mono[1:window_size_audio])[30:end]) + 30 - 1)

# ╔═╡ 6cc5875a-0999-429f-8e06-14d747311c12
# plot(τ -> autocorr2(τ, audio_mono, 1, window_size_audio), 0:window_size_audio;)

# ╔═╡ ebb568ff-b3df-4f79-8eb1-5b0fb9e9dbf9
md"We see at least two frequencies in there"

# ╔═╡ a3ad1215-b1a8-4120-b7f1-d73d79800ffd
plot(m_fast(audio_mono[1:window_size_audio], autocorr_fast(audio_mono[1:window_size_audio])))

# ╔═╡ ca621e88-2f04-4392-a5c6-5731e129a926
nsdf_values = nsdf_fast(audio_mono[1:window_size_audio])

# ╔═╡ 8557da09-e09b-40e1-a421-a125990de331
plot(nsdf_values)

# ╔═╡ 83293e91-813f-47c5-a25d-ec2a9da36032
md"""
### Step 1: Find key maxima

We need to find "highest maximum between every positively sloped zero crossing and negatively sloped zero crossing". With two conditions:
1. The first maxima at 0 is ignored.
2. If there is no negatively sloped zero crossing for the last positively sloped zero crossing, we take the highest maximum anyway (between the positively sloped zero crossing and the last sample).
"""

# ╔═╡ 72e991ff-53a4-4a45-803d-474465ab6e4b
positive_zeroes = zip(
	nsdf_values[2:end],
	nsdf_values[3:end]
) |>
	enumerate |>
	collect |>
	y -> filter(((index, (prev, current)),) -> current >= 0.0 && prev <= 0.0, y) |>
	# why + 1?
	# because of 1-based indexing
	y -> map(((index, (prev, current)),) -> index + 1, y)

# ╔═╡ 6fee9e58-166d-46c7-815f-18ecc6863576
begin
	plot(nsdf_values)
	vline!(positive_zeroes; label="positively sloped zero crossing")
end

# ╔═╡ 8be0bcaf-bb9f-485d-b8c0-1b836d9ed875
negative_zeroes = zip(
	nsdf_values[2:end],
	nsdf_values[3:end]
) |>
	enumerate |>
	collect |>
	y -> filter(((index, (prev, current)),) -> current <= 0.0 && prev >= 0.0, y) |>
	# why + 2?
	# 1. because of 1-based indexing
	# 2. because we want to take the negative value (after it crossed zero)
	y -> map(((index, (prev, current)),) -> index + 2, y)

# ╔═╡ 96e13196-5b90-40b7-9b73-af69808fed13
begin
	plot(nsdf_values)
	vline!(positive_zeroes; label="positively sloped zero crossing")
	vline!(negative_zeroes; label="negatively sloped zero crossing")
end

# ╔═╡ ca14c488-2198-4071-9bda-d0412031d937
# begin
# 	scatter(nsdf_values[1:100])
# 	vline!(positive_zeroes[1:3]; label="positively sloped zero crossing")
# 	vline!(negative_zeroes[1:3]; label="negatively sloped zero crossing")
# end

# ╔═╡ ab88c647-bab2-49aa-9b1e-e6aa4fe1fe30
# TODO: handle case 2: no negative zero for last positive zero
peak_ranges = zip(positive_zeroes, negative_zeroes[2:end]) |> collect

# ╔═╡ f564c56c-44db-49e5-946f-d36d33d2a342
begin
	plot(nsdf_values)
	vspan!(
		peak_ranges |> Iterators.flatten |> collect;
		fillcolor="#FF000034",
		label="ranges to find peaks in"
	)
end

# ╔═╡ 343f269f-7df3-4bf6-9863-ebec49d004b8
key_maxima_indexes = peak_ranges |>
	ranges -> map(
		range ->
			# argmax is inside the range. so add starting value of range to get actual index
			# the -1 is because indexes in Julia start with 1
			range[1] + argmax(nsdf_values[range[1]:range[2]]) - 1,
		ranges
	)

# ╔═╡ b6f2fbce-decf-476a-b11b-d57c59bcd91e
begin
	plot(nsdf_values)
	vline!(
		key_maxima_indexes;
		label="key maxima"
	)
end

# ╔═╡ b21cf728-c185-4fb7-b9aa-5fed0694abb4
md"Let's zoom in a bit to see it more clearly"

# ╔═╡ 0fb896c2-5d91-41ea-b2a7-c115f7409029
begin
	local maxima_to_plot = 2
	local maxima_index = key_maxima_indexes[maxima_to_plot]
	local points = 10
	plot(nsdf_values[maxima_index - points + 1: maxima_index + points - 1])
	scatter!(
		[points],
		[nsdf_values[maxima_index]]
	)
end

# ╔═╡ ed887ccb-df26-463c-8f23-c135706bda68
md"""### Step 2: Parabolic interpolation

The paper says:
> Parabolic interpolation is used to find the positions of the maxima to a higher accuracy. This is done using the highest local value and its two neighbours.

I'm assuming this is the same as **Quadratic Interpolation**. Sources: [[1]](https://www.music.mcgill.ca/~gary/307/week6/node18.html) and [[2]](https://ccrma.stanford.edu/~jos/sasp/Quadratic_Interpolation_Spectral_Peaks.html)

Consider:

``
\begin{align}
α &= y(-1) \textit{ i.e.,}\text{ the point just before the key maxima} \\ 
β &= y(0) \textit{ i.e.,}\text{ the key maxima point} \\ 
γ &= y(1) \textit{ i.e.,}\text{ the point just after the key maxima}
\end{align}
``

The interpolated peak *location* ``p`` in the range ``-1/2\text{ to }1/2``:

``
\begin{equation}
\boxed{p = \frac{1}{2} \frac{α - γ}{α - 2β + γ}}
\end{equation}
``

To get the magnitude of the interpolated peak instead, we can use:

``
\begin{equation}
\boxed{y(p) = β - \frac{1}{4} (α - γ) p}
\end{equation}
``
"""

# ╔═╡ 4d37bbba-28ce-4d58-9396-b4bff09fc31b
function better_peak_index(values, key_maxima_index)
	α = values[key_maxima_index - 1]
	β = values[key_maxima_index]
	γ = values[key_maxima_index + 1]

	p = 0.5 * (α - γ)/(α - 2β + γ)

	return key_maxima_index + p
end

# ╔═╡ 7ca20b37-1660-468c-8ca8-30f56aa36bdd
function better_peak_value(values, key_maxima_index)
	α = values[key_maxima_index - 1]
	β = values[key_maxima_index]
	γ = values[key_maxima_index + 1]

	p = better_peak_index(values, key_maxima_index) - key_maxima_index

	yp = β - 0.25 * (α - γ)p

	return yp
end

# ╔═╡ 729a92ec-8b94-430d-867d-0420d8db90c0
function better_peak_indexes(values, key_maxima_indexes)
	map(index -> better_peak_index(values, index), key_maxima_indexes)
end

# ╔═╡ 10698dfb-9d7f-4c64-b8aa-6d7884bccb4a
function better_peak_values(values, key_maxima_indexes)
	map(index -> better_peak_value(values, index), key_maxima_indexes)
end

# ╔═╡ f6788b79-2c55-4597-88d9-945be41804fc
begin
	maxima_to_plot = 2
	maxima_index = key_maxima_indexes[maxima_to_plot]
	points = 3
	plot(nsdf_values[maxima_index - points + 1: maxima_index + points - 1])
	scatter!(
		[points - 1, points, points + 1],
		[nsdf_values[maxima_index - 1], nsdf_values[maxima_index], nsdf_values[maxima_index + 1]];
		label="original peak"
	)
	scatter!(
		[better_peak_index(nsdf_values, maxima_index) - maxima_index + points], 
		[better_peak_value(nsdf_values, maxima_index)];
		label="interpolated peak"
	)
end

# ╔═╡ 5da8a9fb-3097-4710-bedd-db641c923748
better_key_maxima_indexes = better_peak_indexes(nsdf_values, key_maxima_indexes)

# ╔═╡ ccd4fdf3-63e1-491a-b637-83f8f3781f18
better_key_maxima_values = better_peak_values(nsdf_values, key_maxima_indexes)

# ╔═╡ a2b6f383-42eb-4921-939e-98688289c5a3
better_key_maxima =
	zip(better_key_maxima_indexes, better_key_maxima_values) |>
	collect

# ╔═╡ 3eec6e8b-e479-45d9-aa7f-dd5604b01cf0
md"""### Step 3: choose pitch period"""

# ╔═╡ e6a83ac7-da64-43f9-bca4-6843b6fc27ff
n_max = maximum(better_key_maxima_values)

# ╔═╡ edb95535-ddc6-45e1-ae5a-437cb77b6fa3
@bind k PlutoUI.Slider(0.8:0.01:prevfloat(1.0); default=0.9)

# ╔═╡ d3db7ed0-d757-48d8-a5d9-543943c821ea
k

# ╔═╡ 0fd00e85-eaa7-4809-92a8-b4b62b9912f0
maxima_above_threshold = better_key_maxima |>
	maxima -> filter(((index, value),) -> value > (k * n_max), maxima)

# ╔═╡ 7ed94a63-60e4-42de-9114-25d42778638e
first_maxima_above_threshold = maxima_above_threshold[1]

# ╔═╡ 2796825e-f7ad-4044-9aea-badce3b545c0
begin
	plot(nsdf_values)
	scatter!(
		[first_maxima_above_threshold[1]],
		[first_maxima_above_threshold[2]];
		label="chosen maxima"
	)
end

# ╔═╡ e15a3adb-6b83-4134-9742-61d2acba7429
τ = first_maxima_above_threshold[1]

# ╔═╡ 77545348-f9ff-457a-bc0d-42de0269f905
md"Pitch period is τ=$(τ)"

# ╔═╡ 47cdb2bf-cd51-4ffb-bee4-4a791875e388
pitch_frequency = sample_rate / τ

# ╔═╡ 41b203c3-c78d-40a6-956f-7f60d7fcf558
md"The frequency of the note played in the original sound is $(round(pitch_frequency; digits=2))Hz

This is a bit off from the actual frequency of 220Hz. Why?

---"

# ╔═╡ 5d8bda3f-da5c-4452-b9a8-fa7790645fb2
md"Putting it all together in a single function"

# ╔═╡ 97aab285-29c5-458d-b3cb-bf6ff017067f
function mcleod_pitch_method(audio_window, sample_rate)
	nsdf_values = nsdf_fast(audio_window)
	# window_size = length(audio_window)
	# nsdf_values = map(τ -> nsdf(τ, audio_window, 1, window_size), 0:window_size)

	consecutive_values = zip(
		nsdf_values[2:end],
		nsdf_values[3:end]
	) |>
		enumerate |>
		collect

	positive_zeroes = consecutive_values |>
		y -> filter(((index, (prev, current)),) -> current >= 0.0 && prev <= 0.0, y) |>
		y -> map(((index, (prev, current)),) -> index, y)

	negative_zeroes = consecutive_values |>
		y -> filter(((index, (prev, current)),) -> current <= 0.0 && prev >= 0.0, y) |>
		y -> map(((index, (prev, current)),) -> index, y)

	# TODO: handle case 2: no negative zero for last positive zero
	peak_ranges = zip(positive_zeroes, negative_zeroes[2:end]) |> collect

	key_maxima_indexes = peak_ranges |>
		ranges -> map(
			range ->
				# argmax is inside the range. so add starting value of range to get actual index
				# the -1 is because indexes in Julia start with 1
				range[1] + argmax(nsdf_values[range[1]:range[2]]) - 1,
			ranges
		)

	if length(key_maxima_indexes) == 0
		return 0
	end

	better_key_maxima_indexes = better_peak_indexes(nsdf_values, key_maxima_indexes)
	better_key_maxima_values = better_peak_values(nsdf_values, key_maxima_indexes)
	better_key_maxima =
		zip(better_key_maxima_indexes, better_key_maxima_values) |>
		collect

	n_max = maximum(better_key_maxima_values)
	k = 0.9

	maxima_above_threshold = better_key_maxima |>
		maxima -> filter(((index, value),) -> value > (k * n_max), maxima)

	first_maxima_above_threshold = maxima_above_threshold[1]
	τ = first_maxima_above_threshold[1]
	pitch_frequency = sample_rate / τ

	return pitch_frequency
end

# ╔═╡ 7c69fdff-c7a8-4f91-bf3e-716cd9b35600
@bind start PlutoUI.Slider(
	1 :
		window_size_audio÷4 :
		min(window_size_audio*10, length(audio_mono) - window_size_audio);
	default=1
)

# ╔═╡ 28c7cd55-6470-47ac-a71c-ece968cc012e
start

# ╔═╡ 2a6f509a-a75b-4dd9-8b7d-67f1d22e8700
mcleod_pitch_method(audio_mono[start : start + window_size_audio - 1], sample_rate)

# ╔═╡ 57643ef5-5170-4c5e-a296-275c09d64570
begin
	plot(audio_mono)
	vspan!(
		[start, start + window_size_audio - 1];
		fillcolor="#FF000034",
		label="ranges to find peaks in"
	)
end

# ╔═╡ b21724f0-82a5-4cc5-a2fa-c1f10b195a03
begin
	fs = 44100
	t = 0.0:1/fs:prevfloat(1.0)
	f = 220
	y = sin.(2pi * f * t) * 0.1
	wavwrite(y, "example.wav", Fs=fs)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
MusicProcessing = "32bb9398-a9ad-408c-b137-8304ef5cbed9"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
WAV = "8149f6b0-98f6-5db9-b78f-408fbbb8ef88"

[compat]
FFTW = "~1.8.1"
FileIO = "~1.17.0"
HTTP = "~1.10.16"
MusicProcessing = "~2.0.0"
Plots = "~1.40.13"
PlutoUI = "~0.7.62"
WAV = "~1.2.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "4aa43c34434c9ae09c3aec8547dc6a1370cc082d"

[[deps.ANSIColoredPrinters]]
git-tree-sha1 = "574baf8110975760d391c710b6341da1afa48d8c"
uuid = "a4c015fc-c6ff-483c-b24f-f7ea428134e9"
version = "0.0.1"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

    [deps.AbstractFFTs.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BerkeleyDB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "OpenSSL_jll"]
git-tree-sha1 = "77a1bd0eed92aae78fa1bb1318ac53d3c617e9d3"
uuid = "cd00e070-8fe2-570d-8212-aefc8f89bd06"
version = "18.1.41+0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.BlueZ_jll]]
deps = ["Artifacts", "Dbus_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libical_jll", "Pkg", "Readline_jll", "eudev_jll"]
git-tree-sha1 = "d4c413db1759fa113135800ff2993ee01206126b"
uuid = "471b5b61-da80-5748-8755-67d5084d21f2"
version = "5.54.0+1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2ac646d71d0d24b44f3f8c84da8c9f4d70fb67df"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.4+0"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "062c5e1a5bf6ada13db96a4ae4749a4c2234f521"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.9"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "403f2d8e209681fcbd9468a8514efff3ea08452e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.29.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "d9d26935a0bcffc87d2613ce14c527c99fc543fd"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.0"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DSP]]
deps = ["Compat", "FFTW", "IterTools", "LinearAlgebra", "Polynomials", "Random", "Reexport", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "0df00546373af8eee1598fb4b2ba480b1ebe895c"
uuid = "717857b8-e6f2-59f4-9121-6e50c889abd2"
version = "0.7.10"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4e1fe97fdaed23e9dc21d4d664bea76b65fc50a0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.22"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "473e9afc9cf30814eb67ffa5f2db7df82c3ad9fd"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.16.2+0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "e7b7e6f178525d17c720ab9c081e4ef04429f860"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.4"

[[deps.Documenter]]
deps = ["ANSIColoredPrinters", "AbstractTrees", "Base64", "CodecZlib", "Dates", "DocStringExtensions", "Downloads", "Git", "IOCapture", "InteractiveUtils", "JSON", "LibGit2", "Logging", "Markdown", "MarkdownAST", "Pkg", "PrecompileTools", "REPL", "RegistryInstances", "SHA", "TOML", "Test", "Unicode"]
git-tree-sha1 = "9d733459cea04dcf1c41522ec25c31576387be8a"
uuid = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
version = "1.10.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.Elfutils_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "XZ_jll", "Zlib_jll", "argp_standalone_jll", "fts_jll", "obstack_jll"]
git-tree-sha1 = "ab92028799ddede63b16af075f8a053a2af04339"
uuid = "ab5a07f8-06af-567f-a878-e8bb879eba5a"
version = "0.189.0+1"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a4be429317c42cfae6a7fc03c31bad1970c310d"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+1"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d55dffd9ae73ff72f1c0482454dcf2ec6c6c4a63"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.5+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "7de7c78d681078f027389e067864a8d53bd7c3c9"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.1"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6d6219a004b8cf1e0b4dbe27a2860b8e04eba0be"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.11+0"

[[deps.FLAC_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "8476481230247b3671a98f8b3072053bb001102a"
uuid = "1d38b3a6-207b-531b-80e8-c83f48dafa73"
version = "1.3.4+2"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "b66970a70db13f45b7e57fbda1736e1cf72174ea"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.17.0"
weakdeps = ["HTTP"]

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "301b5d5d731a0654825f1f2e906990f7141a106b"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.16.0+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "fcb0584ff34e25155876418979d4c8971243bb89"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+2"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.3.0+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "7ffa4049937aeba2e5e1242274dc052b0362157a"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.14"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "98fc192b4e4b938775ecd276ce88f539bcec358e"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.14+0"

[[deps.GSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "56f1e2c9e083e0bb7cf9a7055c280beb08a924c0"
uuid = "1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"
version = "2.7.2+0"

[[deps.GStreamer_jll]]
deps = ["Artifacts", "Elfutils_jll", "GMP_jll", "GSL_jll", "Glib_jll", "JLLWrappers", "LibUnwind_jll", "Libdl", "Pkg", "libcap_jll"]
git-tree-sha1 = "455c99eb5cd91f12943d48f54e34b26765867dc0"
uuid = "aaaaf01e-2457-52c6-9fe8-886f7267d736"
version = "1.20.3+0"

[[deps.Gdbm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Readline_jll"]
git-tree-sha1 = "64929c4ee6b015679b8fc9f2dc36f1b738f13abd"
uuid = "54ca2031-c8dd-5cab-9ed4-295edde1660f"
version = "1.19.0+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Git]]
deps = ["Git_jll"]
git-tree-sha1 = "04eff47b1354d702c3a85e8ab23d539bb7d5957e"
uuid = "d7ba0133-e1db-5d97-8f8c-041e4b3a1eb2"
version = "1.3.1"

[[deps.Git_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "LibCURL_jll", "Libdl", "Libiconv_jll", "OpenSSL_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "2f6d6f7e6d6de361865d4394b802c02fc944fc7c"
uuid = "f8c6e375-362e-5223-8a59-34ff63f689eb"
version = "2.49.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "b0036b392358c80d2d2124746c2bf3d48d457938"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.82.4+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "f93655dc73d7a0b4a368e3c0bce296ae035ad76e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.16"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "55c53be97790242c29031e5cd45e8ac296dadda3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.ICU_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6b1e49820922eca7bfc862442da6e54173a075b4"
uuid = "a51ab1cf-af8e-5615-a023-bc2c838bba6b"
version = "68.2.0+0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "0f14a5456bdc6b9731a5682f439a672750a09e48"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2025.0.4+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.JLFzf]]
deps = ["REPL", "Random", "fzf_jll"]
git-tree-sha1 = "82f7acdc599b65e0f8ccd270ffa1467c21cb647b"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.11"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "872cd273cb995ed873c58f196659e32f11f31543"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.44"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c602b1127f4751facb671441ca72715cc95938a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.3+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "cd10d2cc78d34c0e2a3a36420ab607b611debfbb"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.7"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LazilyInitializedFields]]
git-tree-sha1 = "0f2da712350b020bc3957f269c9caad516383ee0"
uuid = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.LibUnwind_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "745a5e78-f969-53e9-954f-d19f2f74f4e3"
version = "1.7.2+2"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "27ecae93dd25ee0909666e6835051dd684cc035e"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+2"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "ff3b4b9d35de638936a525ecd36e86a8bb919d11"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.0+0"

[[deps.Libical_jll]]
deps = ["Artifacts", "BerkeleyDB_jll", "Glib_jll", "ICU_jll", "JLLWrappers", "Libdl", "Pkg", "XML2_jll"]
git-tree-sha1 = "c61ffd9e8faf24c19a88f369f1966d53967824d1"
uuid = "bce108ef-3f60-5dd0-bcd6-e13a096cb796"
version = "3.0.9+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a31572773ac1b745e0343fe5e2c8ddda7a37e997"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.Libtool_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "9ff403efa5a5dd8c71f77490b98669b9399af391"
uuid = "a76c16ae-fb8f-5ff0-8826-da3b7a640f0b"
version = "2.5.4+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "321ccef73a96ba828cd51f2ab5b9f917fa73945a"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "688d6d9e098109051ae33d126fcfc88c4ce4a021"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.1.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "5de60bc6cb3899cd318d80d627560fae2e2d99ae"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2025.0.1+1"

[[deps.MacroTools]]
git-tree-sha1 = "72aebe0b5051e5143a079a4685a46da330a40472"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.15"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MarkdownAST]]
deps = ["AbstractTrees", "Markdown"]
git-tree-sha1 = "465a70f0fc7d443a00dcdc3267a497397b8a3899"
uuid = "d0879d2d-cac2-40c8-9cee-1863dc0c7391"
version = "0.1.2"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MusicProcessing]]
deps = ["DSP", "Documenter", "FFTW", "FixedPointNumbers", "IntervalSets", "LinearAlgebra", "PortAudio", "Requires", "Revise", "SampledSignals", "Statistics", "TestItemRunner", "Unitful"]
git-tree-sha1 = "fa5a4a1ec6dcd7fcfe821ae8ae468d2ca90a15e9"
uuid = "32bb9398-a9ad-408c-b137-8304ef5cbed9"
version = "2.0.0"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.Ncurses_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b5e7e7ad16adfe5f68530f9f641955b5b0f12bbb"
uuid = "68e3532b-a499-55ff-9963-d1c0c0748b3a"
version = "6.5.1+0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a9697f1d06cc3eb3fb3ad49cc67f2cfabaac31ea"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.16+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3b31172c032a1def20c98dae3f2cdc9d10e3b561"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.56.1+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "809ba625a00c605f8d00cd2a9ae19ce34fc24d68"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.13"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "OrderedCollections", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "555c272d20fc80a2658587fb9bbda60067b93b7c"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.0.19"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsFFTWExt = "FFTW"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"

[[deps.PortAudio]]
deps = ["LinearAlgebra", "SampledSignals", "Suppressor", "alsa_plugins_jll", "libportaudio_jll"]
git-tree-sha1 = "1c485addb6c281f039d406137a71394afdcb3585"
uuid = "80ea8bcb-4634-5cb3-8ee8-a132660d1d2d"
version = "1.3.0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.PulseAudio_jll]]
deps = ["Artifacts", "BlueZ_jll", "Dbus_jll", "FFTW_jll", "GStreamer_jll", "Gdbm_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Libtool_jll", "OpenSSL_jll", "SBC_jll", "SoXResampler_jll", "SpeexDSP_jll", "alsa_jll", "eudev_jll", "libasyncns_jll", "libcap_jll", "libsndfile_jll"]
git-tree-sha1 = "df6d51f380df6e16fdae052e15bd2c02a17fe98f"
uuid = "02771fc1-bdb7-5db5-8d11-300768e00fbd"
version = "15.0.1+0"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll"]
git-tree-sha1 = "e5dd466bf2569fe08c91a2cc29c1003f4797ac3b"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.7.1+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "1a180aeced866700d4bebc3120ea1451201f16bc"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.7.1+1"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "729927532d48cf79f49070341e1d918a65aba6b0"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.7.1+1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Readline_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ncurses_jll"]
git-tree-sha1 = "6044f482a91c7aa2b82ab614aedd726be633ad05"
uuid = "05236dd9-4125-5232-aa7c-9ec0c9b2c25a"
version = "8.2.13+0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegistryInstances]]
deps = ["LazilyInitializedFields", "Pkg", "TOML", "Tar"]
git-tree-sha1 = "ffd19052caf598b8653b99404058fce14828be51"
uuid = "2792f1a3-b283-48e8-9a74-f99dce5104f3"
version = "0.1.0"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Revise]]
deps = ["CodeTracking", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "5cf59106f9b47014c58c5053a1ce09c0a2e0333c"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.7.3"

    [deps.Revise.extensions]
    DistributedExt = "Distributed"

    [deps.Revise.weakdeps]
    Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.SBC_jll]]
deps = ["Libdl", "Pkg", "libsndfile_jll"]
git-tree-sha1 = "34755bff50b6b08988cdfe5fee69c1c1b24ff810"
uuid = "da37f231-8920-5702-a09a-bdd970cb6ddc"
version = "1.4.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SampledSignals]]
deps = ["Base64", "Compat", "DSP", "FFTW", "FixedPointNumbers", "IntervalSets", "LinearAlgebra", "Random", "TreeViews", "Unitful"]
git-tree-sha1 = "0eaf25f56d43267dc58f6989fc79e2043a649ab6"
uuid = "bd7594eb-a658-542f-9e75-4c4d8908c167"
version = "2.1.4"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.SoXResampler_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "a95ff1842456719a727e23fe28712eb26f7818b8"
uuid = "fbe68eb6-6641-54c6-99e3-f7c7c4d73a57"
version = "0.1.3+0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "41852b8679f78c8d8961eeadc8f62cef861a52e3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.SpeexDSP_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "ecc65cb4a4e77f624deae8d881787c789af6deaf"
uuid = "f2f9631b-9a4e-5b48-9975-88f638ec36a7"
version = "1.2.0+0"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "83e6cce8324d49dfaf9ef059227f91ed4441a8e5"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.Suppressor]]
deps = ["Logging"]
git-tree-sha1 = "6dbb5b635c5437c68c28c2ac9e39b87138f37c0a"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.8"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TestItemRunner]]
deps = ["Pkg", "TOML", "Test", "TestItems", "UUIDs"]
git-tree-sha1 = "cb2b53fd36a8fe20c0b9f55da6244eb4818779f5"
uuid = "f8b46487-2199-4994-9208-9a1283c18c0a"
version = "0.2.3"

[[deps.TestItems]]
git-tree-sha1 = "8621ba2637b49748e2dc43ba3d84340be2938022"
uuid = "1c621080-faea-4a02-84b6-bbd5e436b8fe"
version = "0.1.1"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "cbbebadbcc76c5ca1cc4b4f3b0614b3e603b5000"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "c0667a8e676c53d390a09dc6870b3d8d6650e2bf"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.22.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.WAV]]
deps = ["Base64", "FileIO", "Libdl", "Logging"]
git-tree-sha1 = "7e7e1b4686995aaf4ecaaf52f6cd824fa6bd6aa5"
uuid = "8149f6b0-98f6-5db9-b78f-408fbbb8ef88"
version = "1.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "85c7811eddec9e7f22615371c3cc81a504c508ee"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+2"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5db3e9d307d32baba7067b13fc7b5aa6edd4a19a"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.36.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "b8b243e47228b4a3877f1dd6aee0c5d56db7fcf4"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.6+1"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fee71455b0aaa3440dfdd54a9a36ccef829be7d4"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.1+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a3ea76ee3f4facd7a64684f9af25310825ee3668"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.2+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "9c7ad99c629a44f81e7799eb05ec2746abb5d588"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.6+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "b5899b25d17bf1889d25906fb9deed5da0c15b3b"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.12+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "807c226eaf3651e7b2c468f687ac788291f9a89b"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.3+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "a4c0ee07ad36bf8bbce1c3bb52d21fb1e0b987fb"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.7+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "6fcc21d5aea1a0b7cce6cab3e62246abd1949b86"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.0+0"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "984b313b049c89739075b8e2a94407076de17449"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.8.2+0"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll"]
git-tree-sha1 = "a1a7eaf6c3b5b05cb903e35e8372049b107ac729"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.5+0"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "b6f664b7b2f6a39689d822a6300b14df4668f0f4"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.4+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "dbc53e4cf7701c6c7047c51e17d6e64df55dca94"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+1"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "ab2221d309eda71020cdda67a973aa582aa85d69"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+1"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.alsa_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "00460d516f82efdbfd977df914afaf6841fa6b92"
uuid = "45378030-f8ea-5b20-a7c7-1a9d95efb90e"
version = "1.2.13+0"

[[deps.alsa_plugins_jll]]
deps = ["Artifacts", "FFMPEG_jll", "JLLWrappers", "Libdl", "Pkg", "PulseAudio_jll", "alsa_jll", "libsamplerate_jll"]
git-tree-sha1 = "a43b5bcdfadfbe06c42cd6b007572c4806f2c0f7"
uuid = "5ac2f6bb-493e-5871-9171-112d4c21a6e7"
version = "1.2.2+0"

[[deps.argp_standalone_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1f43577dc8d90a1d8aa89a2404cd277e74a043d7"
uuid = "c53206cc-00f7-50bf-ad1e-3ae1f6e49bc3"
version = "1.3.1+1"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fts_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa21810b841ae26d2fc7f780cb1596b4170a4c49"
uuid = "d65627f6-89bd-53e8-8ab5-8b75ff535eee"
version = "1.2.8+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6a34e0e0960190ac2a4363a1bd003504772d631"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.61.1+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0ba42241cb6809f1a278d0bcb976e0483c3f1f2d"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+1"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522c1df09d05a71785765d19c9524661234738e9"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.11.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libasyncns_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "38a54b0ebad9bc225a38106ff66b7827fac5bd9e"
uuid = "ed080073-db63-57db-a029-74e11ae80737"
version = "0.8.0+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libcap_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d85bfefe5250c3bab19ae4726e3b2a7b5054233d"
uuid = "eef66a8b-8d7a-5724-a8d2-7c31ae1e29ed"
version = "2.70.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "068dfe202b0a05b8332f1e8e6b4080684b9c7700"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.47+0"

[[deps.libportaudio_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "alsa_jll"]
git-tree-sha1 = "fbce8030d68816899cd5f068670feaad67e84e4a"
uuid = "2d7b7beb-0762-5160-978e-1ab83a1e8a31"
version = "19.7.0+0"

[[deps.libsamplerate_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "45ba80d9b0a208fd5165d159d93a3725fab0d76b"
uuid = "9427e74d-4e05-59c1-8ff3-7d74b6e52ac8"
version = "0.1.9+0"

[[deps.libsndfile_jll]]
deps = ["Artifacts", "FLAC_jll", "JLLWrappers", "Libdl", "Ogg_jll", "Opus_jll", "Pkg", "alsa_jll", "libvorbis_jll"]
git-tree-sha1 = "f35a5fbfb2b18ff837dec4594c7e096ac6604154"
uuid = "5bf562c0-5a39-5b4f-b979-f64ac885830c"
version = "1.1.0+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.obstack_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5353d2b8d19b8ed8d972a4bed38fff85d27f7f73"
uuid = "c88a4935-d25e-5644-aacc-5db6f1b8ef79"
version = "1.2.3+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d5a767a3bb77135a99e433afe0eb14cd7f6914c3"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2022.0.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "63406453ed9b33a0df95d570816d5366c92b7809"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+2"
"""

# ╔═╡ Cell order:
# ╠═e803b848-84f0-45b4-a4d8-b49088c36915
# ╠═91cf5fdb-32fc-42a3-8e31-084c3e6e10d3
# ╟─0156d327-2766-438c-b43e-248b58136cfa
# ╠═66e74997-aed5-4db3-9e66-fca024f3e00a
# ╠═308b7e30-90ea-4d77-bb9f-cf9bfe4076a1
# ╟─8e9f6c05-b970-496e-8fc9-e25c18954211
# ╟─5abddcfc-7391-4fd3-b19a-1395fbd3e3d5
# ╟─a694da85-365f-4774-a17e-83d4b986f69d
# ╠═cf319412-86e6-438f-bdf4-ee374dc1955d
# ╠═113aea2a-f1f0-48b6-8b52-bb5a5c156fba
# ╠═760e0e83-ca35-43e5-a5fd-e4855ce456ea
# ╠═2e28b639-6170-48fe-bab9-01ab420d5b51
# ╟─ac5ed299-9c8b-4b04-85e3-985f018df6e0
# ╟─abdc100b-4daf-49db-b910-e3bfe710ee6f
# ╠═131963c2-ff7f-4c8f-99c0-58b75d824eff
# ╠═9b9129ab-a8ea-4d42-9bf0-fc30af661593
# ╠═f61328df-17b1-45cb-9c4e-d36d2a2174a8
# ╟─a68371ba-c898-4605-b0cf-781b339c595f
# ╠═945e4416-c0f2-46bf-a46d-d66b04676d90
# ╠═27f61efa-daa6-41d8-ac29-307ee7da8f07
# ╟─44e9953b-700b-4d59-be1e-d6b6e7a7a434
# ╟─6913e83e-4847-46bc-ad90-b7491940f651
# ╟─5a6bfbea-90d9-482e-bb1f-490f03fe100d
# ╟─7ffeb5f6-1ef1-4644-bdc8-21d561fda663
# ╠═763871bb-968e-461d-9ec4-b82d0f1bacb6
# ╠═443797a1-eaa3-4b4b-8fed-531c02797715
# ╟─ed34dc0b-8fbe-4507-a4b6-b740caef0aa7
# ╠═2f9c94e6-fffd-4052-82ce-56c30ae98700
# ╠═419c36fd-2e43-4325-ae3b-a126eb24a079
# ╟─014ad646-822a-45d3-b07a-2c75b537b3f5
# ╟─d3ed368e-0bd0-4349-8115-036a3d3c4ff1
# ╟─f0283499-6cd1-45a0-823b-da17b9152729
# ╠═c042d49f-18f8-4396-9f95-f3933f6aa910
# ╠═39a3f283-dd5d-4db8-b475-4eeb4f2db8c7
# ╠═f1b8a4ce-009c-45c7-9375-5f8a01811697
# ╠═9d66347a-3dd2-4882-80f0-38fe2da9c6f3
# ╟─7bf8c5f9-9087-431c-82c3-6cb798a5c6f7
# ╠═4b14fdcf-f80d-4542-a03f-d7465c8b50ac
# ╠═b28f5d7c-8aab-43f2-940a-5487f46f8794
# ╟─3df96ed5-cd1c-4ea0-aa79-92b363251728
# ╟─f849bef5-55fd-47ea-97e5-5b035fef8d8d
# ╠═62b3a61a-ce32-40d1-90c6-34f3bd3241bf
# ╠═7e2858c2-4ef5-4338-8acb-1435eeddde69
# ╟─200e747c-277f-44fc-a121-14468f9ec871
# ╠═52c07508-5aa0-4abb-ae3b-130b5690a10d
# ╠═3085b046-71ad-47de-a9f7-d9477f520e84
# ╟─27c2f914-5fc0-4233-9e45-c7d738ad8725
# ╠═f1602df0-ce3f-459a-98cc-8bb6d3d100a4
# ╠═6fe0bc99-1fca-484f-8d4e-3b3f42b12db4
# ╠═47d03ef6-2273-4a32-b51b-cf07a20f4e82
# ╟─01d7af69-d97b-4e83-a452-7ab374f45804
# ╠═d009cb3e-eada-45e6-bfe0-c682b11e9dc3
# ╟─c78eb5af-b2b0-45da-b5cd-e381769c36bf
# ╠═2dd0fc03-80fb-49dc-bdd5-b5539dc07661
# ╟─676373d9-48b0-479e-8ec0-11a49dbeae02
# ╠═a7926231-bfb6-4aaf-bd5c-c11fee9b605d
# ╠═f21abc4f-25b1-43ed-a2e3-45185c5595fa
# ╟─6141119b-0e10-4473-a862-9d8fd735a5a6
# ╠═107393b3-1efe-40aa-8529-e4e88c3c8a8c
# ╠═4fb10cf7-aef4-41cd-8579-9febf5a6c56c
# ╟─c1b62417-c1e6-4068-9961-f57595135974
# ╟─4771b76b-45e9-4969-bca4-8823b742f486
# ╠═563e5463-2c59-4393-bebf-50a9496f5e27
# ╠═cc13576f-c390-4836-9a57-9b5699782079
# ╠═25184836-19c3-46bf-978c-3495b7508fd0
# ╠═e9c87223-73ce-4ce8-b19f-27d3c5103b58
# ╟─78905af5-403d-4fc1-be2d-50d9e8307e85
# ╟─8f065ce4-550b-4dde-80e5-f37cc272e1dc
# ╠═eb5280ac-bbf6-4637-bc13-6e6a0e0e0c1e
# ╠═fb0df150-8948-4822-9893-17e30ae1d7a0
# ╠═2727c889-166f-4ff3-a66f-9ebf80069c08
# ╠═65e51277-e7b3-4473-91ae-4c8524b906e9
# ╠═fd6b9dfb-53b1-4269-a179-42ff58b1b9dd
# ╠═785e5b03-5486-4c57-8130-8aabfdb89993
# ╟─768a1d2a-a091-4276-a0fa-31c1841e70e9
# ╠═3135f531-bf5b-4a4a-819d-09974ec85145
# ╟─c768b564-489f-45aa-ac7a-2a7adb5f70a2
# ╠═03f071c5-d28e-4dd4-bdf9-a9f6bf24a744
# ╟─71824aa1-1a7f-4afc-9a72-901be686c16a
# ╠═e8a9f572-c9a9-46d9-99c6-3f214d8e7639
# ╟─268b6cf5-0cc7-4282-afcb-151fa65c6acf
# ╠═aae1b32b-8f2b-46a7-9268-c25e2293bf02
# ╠═12c5ae51-fe2d-4758-916b-e8d8f54db529
# ╠═6cc5875a-0999-429f-8e06-14d747311c12
# ╟─ebb568ff-b3df-4f79-8eb1-5b0fb9e9dbf9
# ╠═a3ad1215-b1a8-4120-b7f1-d73d79800ffd
# ╠═ca621e88-2f04-4392-a5c6-5731e129a926
# ╠═8557da09-e09b-40e1-a421-a125990de331
# ╟─83293e91-813f-47c5-a25d-ec2a9da36032
# ╠═72e991ff-53a4-4a45-803d-474465ab6e4b
# ╠═6fee9e58-166d-46c7-815f-18ecc6863576
# ╠═8be0bcaf-bb9f-485d-b8c0-1b836d9ed875
# ╠═96e13196-5b90-40b7-9b73-af69808fed13
# ╠═ca14c488-2198-4071-9bda-d0412031d937
# ╠═ab88c647-bab2-49aa-9b1e-e6aa4fe1fe30
# ╠═f564c56c-44db-49e5-946f-d36d33d2a342
# ╠═343f269f-7df3-4bf6-9863-ebec49d004b8
# ╠═b6f2fbce-decf-476a-b11b-d57c59bcd91e
# ╟─b21cf728-c185-4fb7-b9aa-5fed0694abb4
# ╠═0fb896c2-5d91-41ea-b2a7-c115f7409029
# ╟─ed887ccb-df26-463c-8f23-c135706bda68
# ╠═4d37bbba-28ce-4d58-9396-b4bff09fc31b
# ╠═7ca20b37-1660-468c-8ca8-30f56aa36bdd
# ╠═729a92ec-8b94-430d-867d-0420d8db90c0
# ╠═10698dfb-9d7f-4c64-b8aa-6d7884bccb4a
# ╠═f6788b79-2c55-4597-88d9-945be41804fc
# ╠═5da8a9fb-3097-4710-bedd-db641c923748
# ╠═ccd4fdf3-63e1-491a-b637-83f8f3781f18
# ╠═a2b6f383-42eb-4921-939e-98688289c5a3
# ╟─3eec6e8b-e479-45d9-aa7f-dd5604b01cf0
# ╠═e6a83ac7-da64-43f9-bca4-6843b6fc27ff
# ╠═edb95535-ddc6-45e1-ae5a-437cb77b6fa3
# ╠═d3db7ed0-d757-48d8-a5d9-543943c821ea
# ╠═0fd00e85-eaa7-4809-92a8-b4b62b9912f0
# ╠═7ed94a63-60e4-42de-9114-25d42778638e
# ╠═2796825e-f7ad-4044-9aea-badce3b545c0
# ╠═e15a3adb-6b83-4134-9742-61d2acba7429
# ╟─77545348-f9ff-457a-bc0d-42de0269f905
# ╠═47cdb2bf-cd51-4ffb-bee4-4a791875e388
# ╟─41b203c3-c78d-40a6-956f-7f60d7fcf558
# ╟─5d8bda3f-da5c-4452-b9a8-fa7790645fb2
# ╠═97aab285-29c5-458d-b3cb-bf6ff017067f
# ╠═7c69fdff-c7a8-4f91-bf3e-716cd9b35600
# ╠═28c7cd55-6470-47ac-a71c-ece968cc012e
# ╠═2a6f509a-a75b-4dd9-8b7d-67f1d22e8700
# ╠═57643ef5-5170-4c5e-a296-275c09d64570
# ╠═b21724f0-82a5-4cc5-a2fa-c1f10b195a03
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
